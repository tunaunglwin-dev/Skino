<?php

namespace App\Services\Ai;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class RoutineAssistant
{
    /**
     * @param  array<string, mixed>  $context
     */
    public function reply(string $message, array $context): string
    {
        $apiKey = (string) config('services.gemini.api_key', '');

        if ($apiKey === '') {
            if ((bool) config('services.gemini.demo_fallback', true)) {
                return $this->demoReply($message, $context);
            }

            throw new RuntimeException('Gemini API key is not configured. Add GEMINI_API_KEY to backend-laravel/.env, then run php artisan config:clear.');
        }

        $model = $this->normalizedModel((string) config('services.gemini.model', 'gemini-2.5-flash'));
        $baseUrl = rtrim((string) config('services.gemini.base_url', 'https://generativelanguage.googleapis.com/v1beta'), '/');
        $timeout = (int) config('services.gemini.timeout', 12);

        try {
            $response = Http::timeout($timeout)
                ->acceptJson()
                ->withHeaders(['x-goog-api-key' => $apiKey])
                ->post("{$baseUrl}/models/{$model}:generateContent", [
                    'systemInstruction' => [
                        'parts' => [[
                            'text' => $this->systemInstruction(),
                        ]],
                    ],
                    'contents' => [[
                        'role' => 'user',
                        'parts' => [[
                            'text' => $this->buildPrompt($message, $context),
                        ]],
                    ]],
                    'generationConfig' => [
                        'temperature' => 0.28,
                        'maxOutputTokens' => 520,
                    ],
                ]);

            $response->throw();
        } catch (ConnectionException|RequestException $exception) {
            throw new RuntimeException('Gemini assistant is unavailable right now.', previous: $exception);
        }

        $parts = Arr::get($response->json(), 'candidates.0.content.parts', []);
        $reply = collect(is_array($parts) ? $parts : [])
            ->pluck('text')
            ->filter(fn ($part) => is_string($part) && trim($part) !== '')
            ->implode("\n");

        if (trim($reply) === '') {
            throw new RuntimeException('Gemini returned an empty assistant response.');
        }

        return trim($reply);
    }

    private function systemInstruction(): string
    {
        return <<<'TEXT'
You are Skino Buddy, a small skincare assistant inside the Skino mobile app.
Only answer using the provided latest scan and routine context. Be concise, practical, and reassuring.
Every answer must use Myanmar + English subtitle style:
- First write the Myanmar explanation.
- Then write a short English subtitle under it, prefixed with "EN:".
When scan context exists, explain the relevant details in this order when useful: skin type, confidence, acne severity, each concern, score meaning, scan quality, skin zones, and why the routine was recommended.
Do not invent scan details that are missing from context. If a field is missing, say the app has not received that detail yet.
Use simple skincare words. Avoid heavy medical language.
You may explain routine steps, scan quality, next scan timing, and gentle non-medical skin care habits.
Do not diagnose disease, prescribe medicine, identify a person, or give urgent medical instructions.
If the user describes pain, infection signs, spreading rash, severe swelling, or uncertainty, recommend a qualified specialist.
For moderate or severe acne, low scan quality, pain, swelling, or uncertainty, gently suggest specialist review.
TEXT;
    }

    /**
     * @param  array<string, mixed>  $context
     */
    private function buildPrompt(string $message, array $context): string
    {
        $compactContext = $this->compact($context);
        $safeMessage = mb_substr(trim($message), 0, 500);

        return "Latest app context:\n{$compactContext}\n\nUser question:\n{$safeMessage}";
    }

    /**
     * @param  array<string, mixed>  $context
     */
    private function compact(array $context): string
    {
        $scan = is_array($context['scan'] ?? null) ? $context['scan'] : [];
        $routine = is_array($context['routine'] ?? null) ? $context['routine'] : [];

        $lines = [];

        if ($scan !== []) {
            $lines[] = 'Scan:';
            $this->append($lines, 'skin type', $scan['skin_type'] ?? null);
            $this->append($lines, 'skin health score', $scan['skin_health_score'] ?? null);
            $this->append($lines, 'acne severity', $scan['acne_severity'] ?? null);
            $this->append($lines, 'concerns', $scan['concerns'] ?? null);
            $this->append($lines, 'scan quality', $scan['scan_quality'] ?? null);
            $this->append($lines, 'skin zones', $scan['skin_zones'] ?? null);
            $this->append($lines, 'recommended plan', $scan['treatment_package'] ?? null);
        }

        if ($routine !== []) {
            $lines[] = 'Active routine:';
            $this->append($lines, 'name', $routine['name'] ?? null);
            $this->append($lines, 'started at', $routine['started_at'] ?? null);
            $this->append($lines, 'follow up days', $routine['follow_up_days'] ?? null);
            $this->append($lines, 'today', $routine['today'] ?? null);
            $this->append($lines, 'steps', $routine['steps'] ?? null);
        }

        return $lines === [] ? 'No scan or routine is available yet.' : implode("\n", $lines);
    }

    /**
     * @param  array<int, string>  $lines
     */
    private function append(array &$lines, string $label, mixed $value): void
    {
        if ($value === null || $value === '' || $value === []) {
            return;
        }

        if (is_array($value)) {
            $value = json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }

        $lines[] = "- {$label}: {$value}";
    }

    private function normalizedModel(string $model): string
    {
        return preg_replace('#^models/#', '', trim($model)) ?: 'gemini-2.5-flash';
    }

    /**
     * @param  array<string, mixed>  $context
     */
    private function demoReply(string $message, array $context): string
    {
        $scan = is_array($context['scan'] ?? null) ? $context['scan'] : [];
        $routine = is_array($context['routine'] ?? null) ? $context['routine'] : [];
        $lowerMessage = mb_strtolower($message);
        $skinType = (string) ($scan['skin_type'] ?? 'your skin');
        $score = $scan['skin_health_score'] ?? null;
        $steps = is_array($routine['steps'] ?? null) ? array_slice($routine['steps'], 0, 3) : [];

        if (str_contains($lowerMessage, 'rescan') || str_contains($lowerMessage, 'scan')) {
            return "စကင်ကို routine cycle ပြီးချိန်မှာ ပြန်လုပ်ပါ။ အလင်းမကောင်း၊ မျက်နှာမပြည့်၊ blur ဖြစ်ရင်တော့ အခုချက်ချင်း ပြန်စကင်လုပ်တာ ပိုတိကျပါမယ်။ မျက်နှာကိုရှင်းရှင်းထားပြီး အလင်းညီတဲ့နေရာမှာ စကင်လုပ်ပါ။\n\nEN: Rescan after the routine cycle, or sooner if the photo was dark, blurry, or off-center. Use even light and keep the full face clear.";
        }

        if (str_contains($lowerMessage, 'result') || str_contains($lowerMessage, 'score')) {
            $scoreText = is_numeric($score) ? " Your latest score is {$score}/100." : '';

            return "နောက်ဆုံးစကင်အရ {$skinType} skin အတွက် နူးညံ့ပြီး ပုံမှန်လုပ်နိုင်တဲ့ care ကို အကြံပြုထားပါတယ်။{$scoreText} ဒီရလဒ်က skincare guidance ဖြစ်ပြီး medical diagnosis မဟုတ်ပါ။\n\nEN: Your latest scan suggests {$skinType} skin needs gentle, consistent care.{$scoreText} This is skincare guidance, not a medical diagnosis.";
        }

        if ($steps !== []) {
            return 'ဒီနေ့အတွက် simple routine နဲ့သွားပါ: '.implode(', ', $steps)."။ Strong product များကို တစ်ပြိုင်နက် မရောပါနဲ့။ နာခြင်း၊ ရောင်ခြင်း၊ အရမ်းယားခြင်းရှိရင် specialist ကိုမေးပါ။\n\nEN: Keep today simple: ".implode(', ', $steps).'. Avoid mixing too many strong products, and ask a specialist if pain, swelling, or strong irritation appears.';
        }

        return "ဒီ demo မှာ အရင်ဆုံး gentle cleanser, light moisturizer, sunscreen နဲ့စပါ။ ပိုတိကျတဲ့ routine guidance ရချင်ရင် face scan တစ်ခုလုပ်ပေးပါ။\n\nEN: Start with a gentle cleanse, light moisturizer, and sunscreen. Run a scan so Buddy can give more specific routine guidance.";
    }
}
