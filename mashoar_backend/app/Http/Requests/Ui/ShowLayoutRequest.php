<?php

namespace App\Http\Requests\Ui;

use Illuminate\Foundation\Http\FormRequest;

class ShowLayoutRequest extends FormRequest
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
            'platform' => ['sometimes', 'string', 'in:mobile,web'],
            'locale' => ['sometimes', 'string', 'max:10'],
        ];
    }
}
