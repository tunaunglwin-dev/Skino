<?php

namespace App\Services\Ai;

use Illuminate\Http\Client\RequestException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class SkinAnalyzer
{
    /**
     * @return array<string, mixed>
     */
    public function analyze(UploadedFile $image): array
    {
        $baseUrl = rtrim((string) config('services.skin_ai.base_url'), '/');

        if ($baseUrl === '') {
            throw new RuntimeException('Skin AI service URL is not configured.');
        }

        try {
            $response = Http::timeout((int) config('services.skin_ai.timeout', 15))
                ->attach(
                    'image',
                    file_get_contents($image->getRealPath()),
                    $image->getClientOriginalName() ?: 'skin-image.jpg',
                )
                ->post($baseUrl.'/analyze')
                ->throw()
                ->json();
        } catch (RequestException $exception) {
            throw new RuntimeException('Skin AI service request failed.', previous: $exception);
        }

        if (! is_array($response)) {
            throw new RuntimeException('Skin AI service returned an invalid response.');
        }

        return $response;
    }
}
