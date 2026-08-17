<?php

namespace App\Services\Contacts;

use App\Models\Contact;
use App\Models\User;

class ContactSyncService
{
    public function syncFromUser(User $user, string $source = Contact::SOURCE_SYSTEM): Contact
    {
        $email = strtolower($user->email);

        $contact = Contact::query()
            ->where('user_id', $user->id)
            ->orWhere('gmail_email', $email)
            ->orWhere('email', $email)
            ->first();

        $payload = [
            'user_id' => $user->id,
            'display_name' => $user->name,
            'contact_type' => $user->isAdmin() ? Contact::TYPE_INTERNAL : Contact::TYPE_USER,
            'source' => $user->google_id ? Contact::SOURCE_GOOGLE : $source,
            'status' => Contact::STATUS_ACTIVE,
            'gmail_email' => $user->google_id ? $email : null,
            'email' => $email,
            'avatar_url' => $user->avatar_url,
            'last_seen_at' => now(),
        ];

        if ($contact) {
            $contact->forceFill($payload)->save();

            return $contact;
        }

        return Contact::query()->create($payload);
    }
}
