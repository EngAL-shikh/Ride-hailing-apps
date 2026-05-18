<?php

namespace App\Http\Requests\Trips;

use Illuminate\Foundation\Http\FormRequest;

class AcceptBidRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'bid_id' => ['required', 'integer', 'exists:trip_bids,id'],
        ];
    }
}
