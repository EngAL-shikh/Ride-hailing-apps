<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UiLayoutResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'key' => $this->key,
            'platform' => $this->platform,
            'locale' => $this->locale,
            'version' => (int) $this->version,
            'payload' => $this->payload,
            'updated_at' => optional($this->updated_at)->toISOString(),
        ];
    }
}
