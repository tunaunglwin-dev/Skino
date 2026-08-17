<?php

namespace App\Http\Requests\Catalog;

use Illuminate\Foundation\Http\FormRequest;

class ProductIndexRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'category' => ['sometimes', 'string', 'max:80', 'exists:product_categories,slug'],
            'skin_type' => ['sometimes', 'string', 'max:80', 'exists:skin_types,slug'],
            'concern' => ['sometimes', 'string', 'max:80', 'exists:skin_concerns,slug'],
            'search' => ['sometimes', 'string', 'min:2', 'max:120'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ];
    }
}
