<?php

namespace Tests\Feature;

use App\Models\Contact;
use App\Models\CrmRecord;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AppointmentRequestApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_can_request_specialist_appointment_after_scan(): void
    {
        $response = $this->postJson('/api/guest/appointment-requests', [
            'name' => 'Mya Thandar',
            'phone' => '09123456789',
            'preferred_contact_method' => 'phone',
            'preferred_date' => now()->addDay()->toIso8601String(),
            'beauty_goal' => 'Calm acne before an event',
            'skin_type' => 'oily',
            'acne_severity' => 'severe',
            'skin_health_score' => 48,
            'concern_summary' => 'Latest scan showed severe acne.',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.source', 'mobile_app')
            ->assertJsonPath('data.priority', CrmRecord::PRIORITY_URGENT)
            ->assertJsonPath('data.stage', CrmRecord::STAGE_APPOINTMENT)
            ->assertJsonPath('data.appointment_status', CrmRecord::APPOINTMENT_SCHEDULED)
            ->assertJsonPath('data.contact.display_name', 'Mya Thandar')
            ->assertJsonPath('data.contact.contact_type', Contact::TYPE_LEAD);

        $this->assertDatabaseHas('contacts', [
            'display_name' => 'Mya Thandar',
            'phone' => '09123456789',
            'contact_type' => Contact::TYPE_LEAD,
        ]);
        $this->assertDatabaseHas('crm_records', [
            'source' => 'mobile_app',
            'priority' => CrmRecord::PRIORITY_URGENT,
        ]);
    }

    public function test_authenticated_user_request_reuses_user_contact(): void
    {
        $user = User::factory()->create([
            'name' => 'Aye Aye',
            'email' => 'aye@example.com',
        ]);
        Sanctum::actingAs($user);

        $this->postJson('/api/appointment-requests', [
            'phone' => '0999888777',
            'preferred_contact_method' => 'viber',
            'beauty_goal' => 'Understand my routine',
            'skin_type' => 'combination',
            'acne_severity' => 'moderate',
            'skin_health_score' => 62,
        ])
            ->assertCreated()
            ->assertJsonPath('data.priority', CrmRecord::PRIORITY_HIGH)
            ->assertJsonPath('data.contact.email', 'aye@example.com')
            ->assertJsonPath('data.contact.user.id', $user->id);

        $this->assertDatabaseHas('contacts', [
            'user_id' => $user->id,
            'display_name' => 'Aye Aye',
            'phone' => '0999888777',
        ]);
    }

    public function test_guest_appointment_request_requires_contact_details(): void
    {
        $this->postJson('/api/guest/appointment-requests', [
            'name' => 'No Contact',
            'acne_severity' => 'mild',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'phone']);
    }
}
