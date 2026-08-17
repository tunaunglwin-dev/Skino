<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('skin_analyses', function (Blueprint $table) {
            $table->string('acne_severity')->default('none')->after('concerns')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('skin_analyses', function (Blueprint $table) {
            $table->dropColumn('acne_severity');
        });
    }
};
