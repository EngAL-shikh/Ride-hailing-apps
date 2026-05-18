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
        Schema::create('ui_layouts', function (Blueprint $table) {
            $table->id();
            $table->string('key', 100)->index();
            $table->string('platform', 30)->default('mobile')->index(); // mobile|web
            $table->string('locale', 10)->nullable()->index(); // ar|en|...
            $table->unsignedInteger('version')->default(1);
            $table->json('payload');
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();

            $table->unique(['key', 'platform', 'locale']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ui_layouts');
    }
};
