<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TripBidResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'driver_id' => $this->driver_id,
            'amount' => (float) $this->amount,
            'status' => $this->status,
            'created_at' => optional($this->created_at)->toISOString(),
        ];
    }
}
