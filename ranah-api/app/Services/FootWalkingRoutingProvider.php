<?php

namespace App\Services;

interface FootWalkingRoutingProvider
{
    /** @param array<string, mixed> $destination
     * @return array<string, mixed>
     */
    public function route(float $originLatitude, float $originLongitude, array $destination): array;
}
