<?php

namespace Tests\Feature;

use App\Models\Contact;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminContactsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_registering_user_creates_contact_profile(): void
    {
        $this->postJson('/api/auth/register', [
            'name' => 'Mobile User',
            'email' => 'mobile@example.com',
            'password' => 'Secure123',
            'password_confirmation' => 'Secure123',
        ])->assertCreated();

        $this->assertDatabaseHas('contacts', [
            'display_name' => 'Mobile User',
            'email' => 'mobile@example.com',
            'contact_type' => Contact::TYPE_USER,
        ]);
    }

    public function test_admin_can_create_manual_specialist_contact(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $response = $this->postJson('/api/admin/contacts', [
            'display_name' => 'Dr. Hnin',
            'contact_type' => Contact::TYPE_SPECIALIST,
            'email' => 'specialist@example.com',
            'phone' => '+959123456789',
            'specialty' => 'Acne and pigmentation',
            'tags' => ['specialist', 'appointment'],
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.display_name', 'Dr. Hnin')
            ->assertJsonPath('data.contact_type', Contact::TYPE_SPECIALIST)
            ->assertJsonPath('data.source', Contact::SOURCE_MANUAL);
    }

    public function test_admin_can_filter_contacts_and_add_note(): void
    {
        $admin = User::factory()->admin()->create();
        Sanctum::actingAs($admin);

        Contact::factory()->create(['display_name' => 'Regular User']);
        $specialist = Contact::factory()->specialist()->create([
            'display_name' => 'Dr. Acne Care',
        ]);

        $this->getJson('/api/admin/contacts?contact_type=specialist')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.display_name', 'Dr. Acne Care');

        $this->postJson("/api/admin/contacts/{$specialist->id}/notes", [
            'note_type' => 'crm',
            'body' => 'Available for weekend appointments.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.body', 'Available for weekend appointments.');

        $this->assertDatabaseHas('contact_notes', [
            'contact_id' => $specialist->id,
            'author_id' => $admin->id,
            'note_type' => 'crm',
        ]);
    }

    public function test_admin_can_upload_specialist_avatar_but_not_user_avatar(): void
    {
        Storage::fake('public');
        Sanctum::actingAs(User::factory()->admin()->create());

        $specialist = Contact::factory()->specialist()->create();
        $userContact = Contact::factory()->create(['contact_type' => Contact::TYPE_USER]);

        $this->postJson("/api/admin/contacts/{$specialist->id}/avatar", [
            'avatar' => UploadedFile::fake()->image('doctor.png', 256, 256),
        ])
            ->assertOk()
            ->assertJsonPath('data.id', $specialist->id);

        $this->assertNotNull($specialist->refresh()->avatar_url);
        Storage::disk('public')->assertExists('contact-avatars/'.basename($specialist->avatar_url));

        $this->postJson("/api/admin/contacts/{$userContact->id}/avatar", [
            'avatar' => UploadedFile::fake()->image('user.png', 256, 256),
        ])
            ->assertUnprocessable();

        $this->assertNull($userContact->refresh()->avatar_url);
    }

    public function test_non_admin_cannot_access_contacts(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/contacts')
            ->assertForbidden();
    }
}
