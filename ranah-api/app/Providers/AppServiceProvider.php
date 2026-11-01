<?php

namespace App\Providers;

use App\Services\FootWalkingRoutingProvider;
use App\Services\OpenRouteServiceRoutingService;
use App\Services\ValhallaRoutingService;
use Illuminate\Support\ServiceProvider;
use InvalidArgumentException;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(FootWalkingRoutingProvider::class, function ($app): FootWalkingRoutingProvider {
            return match (config('services.routing.provider', 'ors')) {
                'ors' => $app->make(OpenRouteServiceRoutingService::class),
                'valhalla' => $app->make(ValhallaRoutingService::class),
                default => throw new InvalidArgumentException('Unsupported routing provider.'),
            };
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
