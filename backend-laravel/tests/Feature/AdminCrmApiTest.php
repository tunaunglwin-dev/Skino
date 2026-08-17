<?php

namespace Tests\Feature;

use App\Models\Contact;
use App\Models\CrmRecord;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminCrmApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_crm_appointment_record(): void
    {
        $admin = User::factory()->admin()->create();
        $client = Contact::factory()->create(['display_name' => 'Aye Chan']);
        $specialist = Contact::factory()->specialist()->create(['display_name' => 'Dr. Hnin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/crm-records', [
            'contact_id' => $client->id,
            'specialist_contact_id' => $specialist->id,
            'title' => 'Acne specialist consultation',
            'stage' => CrmRecord::STAGE_APPOINTMENT,
            'priority' => CrmRecord::PRIORITY_HIGH,
            'appointment_status' => CrmRecord::APPOINTMENT_SCHEDULED,
            'scheduled_at' => '2026-07-25T10:30:00+06:30',
            'beauty_goal' => 'Calm acne and improve confidence',
            'concern_summary' => 'Moderate acne severity from latest scan.',
            'tags' => ['acne', 'specialist'],
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'Acne specialist consultation')
            ->assertJsonPath('data.contact.display_name', 'Aye Chan')
            ->assertJsonPath('data.specialist.display_name', 'Dr. Hnin')
            ->assertJsonPath('data.owner.id', $admin->id);
    }

    public function test_admin_can_filter_update_and_note_crm_record(): void
    {
        $admin = User::factory()->admin()->create();
        Sanctum::actingAs($admin);

        CrmRecord::factory()->create(['stage' => CrmRecord::STAGE_NEW]);
        $record = CrmRecord::factory()->create([
            'title' => 'Follow up with specialist',
            'stage' => CrmRecord::STAGE_CONTACTED,
        ]);

        $this->getJson('/api/admin/crm-records?stage=contacted')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Follow up with specialist');

        $this->putJson("/api/admin/crm-records/{$record->id}", [
            'contact_id' => $record->contact_id,
            'title' => 'Appointment completed',
            'stage' => CrmRecord::STAGE_COMPLETED,
            'priority' => CrmRecord::PRIORITY_NORMAL,
            'appointment_status' => CrmRecord::APPOINTMENT_COMPLETED,
        ])
            ->assertOk()
            ->assertJsonPath('data.stage', CrmRecord::STAGE_COMPLETED)
            ->assertJsonPath('data.appointment_status', CrmRecord::APPOINTMENT_COMPLETED);

        $this->postJson("/api/admin/crm-records/{$record->id}/notes", [
            'note_type' => 'appointment',
            'body' => 'Specialist recommended calm routine for two weeks.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.body', 'Specialist recommended calm routine for two weeks.');
    }

    public function test_non_admin_cannot_access_crm_records(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/crm-records')->assertForbidden();
        $this->postJson('/api/admin/crm-records', [])->assertForbidden();
    }
}
