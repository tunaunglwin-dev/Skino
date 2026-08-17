<?php

namespace Database\Factories;

use App\Models\SkinAnalysis;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SkinAnalysis>
 */
class SkinAnalysisFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'image_path' => 'skin-analyses/'.fake()->uuid().'.jpg',
            'skin_type_slug' => 'oily',
            'skin_type_confidence' => 0.8200,
            'concerns' => [
                ['name' => 'acne', 'confidence' => 0.76, 'severity' => 'moderate'],
            ],
            'acne_severity' => 'moderate',
            'skin_health_score' => 68,
            'ai_provider' => 'skin-ai-service',
            'raw_result' => [
                'skin_type' => 'oily',
                'skin_type_confidence' => 0.82,
                'concerns' => [
                    ['name' => 'acne', 'confidence' => 0.76, 'severity' => 'moderate'],
                ],
                'acne_severity' => 'moderate',
                'skin_health_score' => 68,
            ],
        ];
    }
}
