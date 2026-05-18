<?php

namespace App\Traits;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Trait for syncing data to Firebase Realtime Database via HTTP REST API.
 * Uses simple HTTP/CURL instead of heavy gRPC Admin SDK (suitable for shared hosting).
 */
trait FirebaseSync
{
    /**
     * Get Firebase Database URL from config.
     */
    protected function getFirebaseDatabaseUrl(): ?string
    {
        $url = (string) config('services.firebase.database_url', '');
        
        if ($url === '') {
            Log::warning('[FirebaseSync] FIREBASE_DB_URL or FIREBASE_DATABASE_URL not configured. Please add one of them to .env file');
            Log::warning('[FirebaseSync] Expected format: FIREBASE_DB_URL=https://PROJECT_ID-default-rtdb.REGION.firebasedatabase.app');
            Log::warning('[FirebaseSync] Or: FIREBASE_DATABASE_URL=https://PROJECT_ID-default-rtdb.REGION.firebasedatabase.app');
            return null;
        }

        // Remove trailing slash
        $url = rtrim($url, '/');
        Log::debug('[FirebaseSync] Using Firebase Database URL: ' . substr($url, 0, 50) . '...');
        return $url;
    }

    /**
     * Get Firebase Database Secret (for legacy auth) or use Service Account token.
     */
    protected function getFirebaseAuthToken(): ?string
    {
        // Try Database Secret first (legacy auth)
        $secret = (string) config('services.firebase.database_secret', '');
        if ($secret !== '') {
            return $secret;
        }

        // If no secret, we'll use Service Account token (requires Admin SDK)
        // For now, return null and let the caller handle it
        return null;
    }

    /**
     * Update a Firebase RTDB node using HTTP PATCH.
     *
     * @param  string  $path  Firebase path (e.g., 'trips/123' or 'trips/123/bids/456')
     * @param  array<string, mixed>  $data  Data to update
     * @param  bool  $merge  If true, merge with existing data. If false, replace.
     */
    protected function updateFirebaseNode(string $path, array $data, bool $merge = true): bool
    {
        $baseUrl = $this->getFirebaseDatabaseUrl();
        if ($baseUrl === null) {
            return false;
        }

        // Remove leading slash from path
        $path = ltrim($path, '/');
        
        // Build URL with .json extension
        $url = "{$baseUrl}/{$path}.json";

        // Add auth token if available
        $authToken = $this->getFirebaseAuthToken();
        if ($authToken !== null) {
            $url .= "?auth={$authToken}";
        }

        try {
            $method = $merge ? 'PATCH' : 'PUT';
            
            $response = Http::timeout(5)
                ->withHeaders([
                    'Content-Type' => 'application/json',
                ])
                ->send($method, $url, [
                    'body' => json_encode($data),
                ]);

            if ($response->successful()) {
                Log::debug('[FirebaseSync] ✓ Successfully updated Firebase node', [
                    'path' => $path,
                    'method' => $method,
                ]);
                return true;
            }

            Log::error('[FirebaseSync] ✗ Failed to update Firebase node', [
                'path' => $path,
                'status' => $response->status(),
                'body' => substr($response->body(), 0, 200),
            ]);
            return false;
        } catch (\Throwable $e) {
            Log::error('[FirebaseSync] Exception updating Firebase node', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Delete a Firebase RTDB node using HTTP DELETE.
     *
     * @param  string  $path  Firebase path
     */
    protected function deleteFirebaseNode(string $path): bool
    {
        $baseUrl = $this->getFirebaseDatabaseUrl();
        if ($baseUrl === null) {
            return false;
        }

        $path = ltrim($path, '/');
        $url = "{$baseUrl}/{$path}.json";

        $authToken = $this->getFirebaseAuthToken();
        if ($authToken !== null) {
            $url .= "?auth={$authToken}";
        }

        try {
            $response = Http::timeout(5)->delete($url);

            if ($response->successful()) {
                Log::info('[FirebaseSync] ✓ Successfully deleted Firebase node', ['path' => $path]);
                return true;
            }

            Log::error('[FirebaseSync] ✗ Failed to delete Firebase node', [
                'path' => $path,
                'status' => $response->status(),
                'body' => substr($response->body(), 0, 200),
            ]);
            return false;
        } catch (\Throwable $e) {
            Log::error('[FirebaseSync] Exception deleting Firebase node', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Set a Firebase RTDB node (replace entire node).
     *
     * @param  string  $path  Firebase path
     * @param  array<string, mixed>  $data  Data to set
     */
    protected function setFirebaseNode(string $path, array $data): bool
    {
        return $this->updateFirebaseNode($path, $data, false);
    }
}
