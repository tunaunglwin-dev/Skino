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
            'capture_mode' => ['sometimes', 'string', 'in:single_upload,single_camera,multi_frame_best'],
            'frame_count' => ['sometimes', 'integer', 'between:1,8'],
            'client_quality_score' => ['sometimes', 'numeric', 'between:0,100'],
            'device_category' => ['sometimes', 'string', 'in:mobile,tablet,desktop,unknown'],
            'face_landmarks' => ['sometimes', 'string', 'max:120000'],
        ];
    }
}
