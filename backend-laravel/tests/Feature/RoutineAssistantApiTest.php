<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoutineAssistantApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_ask_routine_assistant(): void
    {
        config([
            'services.gemini.api_key' => 'test-gemini-key',
            'services.gemini.model' => 'gemini-2.5-flash',
        ]);

        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => [
                        'parts' => [[
                            'text' => 'Use the gentle cleanser tonight and keep the night routine simple.',
                        ]],
                    ],
                ]],
            ]),
        ]);

        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/chat/routine-assistant', [
            'message' => 'What should I do tonight?',
            'context' => [
                'scan' => [
                    'skin_type' => 'oily',
                    'skin_health_score' => 74,
                    'acne_severity' => 'mild',
                ],
                'routine' => [
                    'name' => 'Oil Balance Care',
                    'today' => [
                        'morning_done' => true,
                        'night_done' => false,
                    ],
                ],
            ],
        ])
            ->assertOk()
            ->assertJsonPath(
                'data.reply',
                'Use the gentle cleanser tonight and keep the night routine simple.',
            );

        Http::assertSent(fn ($request) => $request->hasHeader('x-goog-api-key', 'test-gemini-key')
            && str_contains($request->url(), '/models/gemini-2.5-flash:generateContent')
            && str_contains($request['systemInstruction']['parts'][0]['text'], 'Myanmar + English subtitle style')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'What should I do tonight?'));
    }

    public function test_guest_cannot_use_routine_assistant(): void
    {
        Http::fake();

        $this->postJson('/api/chat/routine-assistant', [
            'message' => 'Can I ask Buddy?',
        ])->assertUnauthorized();

        Http::assertNothingSent();
    }

    public function test_routine_assistant_uses_demo_fallback_when_gemini_key_is_missing(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.gemini.demo_fallback' => true,
        ]);

        Http::fake();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/chat/routine-assistant', [
            'message' => 'Explain my result',
            'context' => [
                'scan' => [
                    'skin_type' => 'sensitive',
                    'skin_health_score' => 57,
                ],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('data.reply', "နောက်ဆုံးစကင်အရ sensitive skin အတွက် နူးညံ့ပြီး ပုံမှန်လုပ်နိုင်တဲ့ care ကို အကြံပြုထားပါတယ်။ Your latest score is 57/100. ဒီရလဒ်က skincare guidance ဖြစ်ပြီး medical diagnosis မဟုတ်ပါ။\n\nEN: Your latest scan suggests sensitive skin needs gentle, consistent care. Your latest score is 57/100. This is skincare guidance, not a medical diagnosis.");

        Http::assertNothingSent();
    }
}
