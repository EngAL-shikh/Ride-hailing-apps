<?php

namespace App\Http\Resources;

use App\Http\Resources\TripBidResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TripResource extends JsonResource
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
            'rider_id' => $this->rider_id,
            'driver_id' => $this->driver_id,
            'pickup' => [
                'lat' => (float) $this->pickup_lat,
                'lng' => (float) $this->pickup_lng,
            ],
            'dropoff' => [
                'lat' => (float) $this->dropoff_lat,
                'lng' => (float) $this->dropoff_lng,
            ],
            'offered_price' => $this->offered_price !== null ? (float) $this->offered_price : null,
            'accepted_price' => $this->accepted_price !== null ? (float) $this->accepted_price : null,
            'status' => $this->status,
            'commission_rate' => (float) $this->commission_rate,
            'commission_amount' => (float) $this->commission_amount,
            'accepted_at' => optional($this->accepted_at)->toISOString(),
            'completed_at' => optional($this->completed_at)->toISOString(),
            'bids' => $this->whenLoaded('bids', function () {
                return TripBidResource::collection($this->bids);
            }),
        ];
    }
}
