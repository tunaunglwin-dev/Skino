<?php

namespace App\Http\Requests\Profile;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'age_band' => ['nullable', Rule::in(['under_18', '18_24', '25_34', '35_44', '45_54', '55_plus', 'prefer_not'])],
            'skin_tone_scale' => ['nullable', 'integer', 'between:1,10'],
            'skin_goals' => ['present', 'array', 'max:5'],
            'skin_goals.*' => ['string', 'distinct', Rule::in(['acne', 'redness', 'pigmentation', 'texture', 'oiliness', 'dryness'])],
        ];
    }
}
