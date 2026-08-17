<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CatalogApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_catalog_endpoints_require_authentication(): void
    {
        $this->getJson('/api/catalog/skin-types')->assertUnauthorized();
        $this->getJson('/api/catalog/products')->assertUnauthorized();
    }

    public function test_authenticated_user_can_read_lookup_catalogs(): void
    {
        $this->seed();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/catalog/skin-types')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'oily');

        $this->getJson('/api/catalog/skin-concerns')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'acne');

        $this->getJson('/api/catalog/product-categories')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'cleanser');
    }

    public function test_authenticated_user_can_filter_products(): void
    {
        $this->seed();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/catalog/products?concern=acne&skin_type=oily&category=cleanser')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'gentle-gel-cleanser')
            ->assertJsonPath('data.0.category.slug', 'cleanser')
            ->assertJsonPath('data.0.skin_types.0.slug', 'oily')
            ->assertJsonStructure([
                'data',
                'links',
                'meta',
            ]);
    }

    public function test_product_filter_validation_rejects_unknown_slugs(): void
    {
        $this->seed();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/catalog/products?concern=unknown')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['concern']);
    }

    public function test_authenticated_user_can_read_product_detail_by_slug(): void
    {
        $this->seed();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/catalog/products/gentle-gel-cleanser')
            ->assertOk()
            ->assertJsonPath('data.slug', 'gentle-gel-cleanser')
            ->assertJsonPath('data.skin_concerns.0.slug', 'acne');
    }

    public function test_inactive_products_are_hidden(): void
    {
        $this->seed();
        Sanctum::actingAs(User::factory()->create());

        Product::query()->where('slug', 'gentle-gel-cleanser')->update(['is_active' => false]);

        $this->getJson('/api/catalog/products')
            ->assertOk()
            ->assertJsonMissing(['slug' => 'gentle-gel-cleanser']);

        $this->getJson('/api/catalog/products/gentle-gel-cleanser')
            ->assertNotFound();
    }
}
