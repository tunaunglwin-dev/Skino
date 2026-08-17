<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\ProductCategory;
use App\Models\SkinConcern;
use App\Models\SkinType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DatabaseFoundationTest extends TestCase
{
    use RefreshDatabase;

    public function test_domain_seeders_create_core_catalog_data(): void
    {
        $this->seed();

        $this->assertDatabaseHas('skin_types', ['slug' => 'oily']);
        $this->assertDatabaseHas('skin_concerns', ['slug' => 'acne']);
        $this->assertDatabaseHas('product_categories', ['slug' => 'cleanser']);
        $this->assertDatabaseHas('products', ['slug' => 'gentle-gel-cleanser']);
    }

    public function test_products_are_linked_to_skin_types_and_concerns(): void
    {
        $this->seed();

        $product = Product::query()
            ->where('slug', 'gentle-gel-cleanser')
            ->with(['category', 'skinTypes', 'skinConcerns'])
            ->firstOrFail();

        $this->assertInstanceOf(ProductCategory::class, $product->category);
        $this->assertTrue($product->skinTypes->contains(fn (SkinType $skinType): bool => $skinType->slug === 'oily'));
        $this->assertTrue($product->skinConcerns->contains(fn (SkinConcern $concern): bool => $concern->slug === 'acne'));
    }

    public function test_seeders_are_idempotent(): void
    {
        $this->seed();
        $this->seed();

        $this->assertSame(5, SkinType::query()->count());
        $this->assertSame(6, SkinConcern::query()->count());
        $this->assertSame(5, ProductCategory::query()->count());
        $this->assertSame(4, Product::query()->count());
    }
}
