<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_skin_type', function (Blueprint $table) {
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('skin_type_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('recommendation_weight')->default(50);
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->primary(['product_id', 'skin_type_id']);
            $table->index(['skin_type_id', 'recommendation_weight']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_skin_type');
    }
};
