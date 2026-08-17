<?php

namespace App\Http\Requests\Analysis;

use Illuminate\Foundation\Http\FormRequest;

class StoreSkinAnalysisRequest extends FormRequest
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
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'image' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
            'allow_model_training' => ['sometimes', 'boolean'],
        ];
    }
}
