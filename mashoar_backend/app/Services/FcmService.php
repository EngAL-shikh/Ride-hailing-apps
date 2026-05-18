<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FcmService
{
    private ?\Kreait\Firebase\Messaging $messaging = null;

    public function __construct()
    {
        $credentialsPath = (string) config('services.firebase.credentials', '');

        if ($credentialsPath === '' || ! is_file($credentialsPath)) {
            // We keep it non-fatal to avoid breaking shared hosting if creds are missing.
            // FCM is an enhancement; core API should still work.
            Log::warning('[FcmService] Missing firebase credentials file, FCM disabled', [
                'credentials' => $credentialsPath,
            ]);

            return;
        }

        $factory = (new Factory())->withServiceAccount($credentialsPath);
        $this->messaging = $factory->createMessaging();
    }

    /**
     * Send a notification to multiple device tokens.
     *
     * @param  array<int, string>  $tokens
     * @param  array<string, string>  $data
     */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): void
    {
        if ($this->messaging === null) {
            return;
        }

        $tokens = array_values(array_filter(array_map('trim', $tokens)));
        if (count($tokens) === 0) {
            return;
        }

        $message = CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData($data);

        try {
            $report = $this->messaging->sendMulticast($message, $tokens);

            if ($report->hasFailures()) {
                foreach ($report->failures()->getItems() as $failure) {
                    Log::warning('[FcmService] FCM send failure', [
                        'token' => $failure->target()->value(),
                        'error' => $failure->error()->getMessage(),
                    ]);
                }
            }
        } catch (\Throwable $e) {
            Log::error('[FcmService] Failed to send FCM multicast', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send a notification to a single device token.
     *
     * @param  array<string, string>  $data
     */
    public function sendToToken(?string $token, string $title, string $body, array $data = []): void
    {
        $token = $token ? trim($token) : '';
        if ($token === '') {
            return;
        }

        $this->sendToTokens([$token], $title, $body, $data);
    }
}

