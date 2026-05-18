<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class VerifyOtpRequest extends FormRequest
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
            'phone' => ['required', 'string', 'min:7', 'max:20'],
            'otp' => ['required', 'string', 'size:4', 'regex:/^[0-9]{4}$/'],
            'device_name' => ['sometimes', 'string', 'max:50'],
            'fcm_token' => ['sometimes', 'string', 'max:255'],
        ];
    }
}
