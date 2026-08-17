<?php

namespace Database\Factories;

use App\Models\Contact;
use App\Models\CrmRecord;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CrmRecord>
 */
class CrmRecordFactory extends Factory
{
    public function definition(): array
    {
        return [
            'contact_id' => Contact::factory(),
            'owner_id' => User::factory()->admin(),
            'title' => 'Specialist appointment request',
            'stage' => CrmRecord::STAGE_NEW,
            'priority' => CrmRecord::PRIORITY_NORMAL,
            'source' => 'admin',
            'appointment_status' => CrmRecord::APPOINTMENT_NOT_SCHEDULED,
            'beauty_goal' => 'Improve acne and face texture',
            'concern_summary' => 'User wants specialist guidance after scan.',
            'tags' => ['appointment'],
        ];
    }
}
