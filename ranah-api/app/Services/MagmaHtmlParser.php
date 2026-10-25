<?php

namespace App\Services;

use DOMDocument;
use DOMElement;
use DOMXPath;
use RuntimeException;

/** Parses only the public HTML fields consumed from MAGMA's pages. */
class MagmaHtmlParser
{
    private const HOST = 'magma.esdm.go.id';

    /** @return list<array{name:string,province:string,status:string,report_id:string,report_url:string}> */
    public function parseActivityListing(string $html): array
    {
        $xpath = $this->xpath($html);
        $rows = [];
        $signedLinkCount = 0;
        $tables = $xpath->query('//table[.//a[@href]]');
        foreach ($tables ?: [] as $table) {
            $status = null;
            foreach ($xpath->query('.//tr', $table) ?: [] as $tableRow) {
                if (! $tableRow instanceof DOMElement) {
                    continue;
                }
                $rowLevel = $this->extractLevel($tableRow->textContent);
                if ($rowLevel !== null) {
                    $status = $rowLevel;
                }

                $anchors = $xpath->query('.//a[@href]', $tableRow);
                foreach ($anchors ?: [] as $anchor) {
                    if (! $anchor instanceof DOMElement) {
                        continue;
                    }
                    $url = $this->signedReportUrl($anchor->getAttribute('href'));
                    if ($url === null) {
                        continue;
                    }
                    $signedLinkCount++;
                    $cells = $xpath->query('./td', $tableRow);
                    $label = trim(preg_replace('/\s+/u', ' ', $cells?->item(0)?->textContent ?? '') ?? '');
                    $label = trim(preg_replace('/\s*Lihat laporan\s*$/iu', '', $label) ?? $label);
                    if ($status === null || ! preg_match('/^(.+?)\s*[-–]\s*(.+)$/u', $label, $locationMatch)) {
                        continue;
                    }

                    $name = trim($locationMatch[1]);
                    $region = trim($locationMatch[2]);
                    $path = (string) parse_url($url, PHP_URL_PATH);
                    if ($name === '' || $region === '' || ! preg_match('~/laporan/(\d+)$~', $path, $idMatch)) {
                        continue;
                    }
                    $rows[] = [
                        'name' => $name,
                        // MAGMA's displayed area can name one or several provinces.
                        'province' => $region,
                        'status' => $status,
                        'report_id' => $idMatch[1],
                        'report_url' => $url,
                    ];
                }
            }
        }

        $reportIds = array_column($rows, 'report_id');
        if ($signedLinkCount === 0 || count($rows) !== $signedLinkCount
            || count(array_unique($reportIds)) !== count($reportIds)) {
            throw new RuntimeException('MAGMA activity page changed or contains incomplete volcano records.');
        }

        return $rows;
    }

    /** @return array{name:string,province:string,status:string,period_date:string,period_time:string,observation:?string,climate:?string,recommendation:?string,latitude:?float,longitude:?float} */
    public function parseReportDetail(string $html): array
    {
        $xpath = $this->xpath($html);
        $title = trim($xpath->evaluate('string(//title)'));
        if ($title === '') {
            $title = trim($xpath->evaluate('string(//h1)'));
        }
        if (! preg_match('/Laporan Aktivitas Gunung Api\s*-\s*(.+?),\s*[^,]+\s*-\s*(\d{1,2}\s+\pL+\s+\d{4}),\s*periode\s+([^<]+)/iu', $title, $titleMatch)) {
            throw new RuntimeException('MAGMA detail title does not match the expected report format.');
        }
        $bodyText = preg_replace('/\s+/u', ' ', trim($xpath->evaluate('string(//body)'))) ?? '';
        $status = $this->extractLevel($bodyText);
        if ($status === null) {
            throw new RuntimeException('MAGMA report activity level is missing.');
        }
        $coordinates = $this->coordinates($html);

        return [
            'name' => trim($titleMatch[1]),
            'province' => '',
            'status' => $status,
            'period_date' => trim($titleMatch[2]),
            'period_time' => trim($titleMatch[3]),
            'observation' => $this->section($xpath, ['Pengamatan Visual', 'Pengamatan']),
            'climate' => $this->section($xpath, ['Data Klimatologi', 'Klimatologi']),
            'recommendation' => $this->section($xpath, ['Rekomendasi']),
            'latitude' => $coordinates[0],
            'longitude' => $coordinates[1],
        ];
    }

    public function signedReportUrl(string $candidate, ?string $baseUrl = null): ?string
    {
        $url = $baseUrl === null ? $candidate : (string) (parse_url($candidate, PHP_URL_SCHEME) ? $candidate : rtrim($baseUrl, '/').'/'.ltrim($candidate, '/'));
        $parts = parse_url($url);
        if (! is_array($parts) || strtolower((string) ($parts['scheme'] ?? '')) !== 'https'
            || strtolower((string) ($parts['host'] ?? '')) !== self::HOST
            || ! preg_match('~^/v1/gunung-api/laporan/\d+$~', (string) ($parts['path'] ?? ''))) {
            return null;
        }
        parse_str((string) ($parts['query'] ?? ''), $query);

        return isset($query['signature']) && is_string($query['signature']) && $query['signature'] !== '' ? $url : null;
    }

    private function xpath(string $html): DOMXPath
    {
        $document = new DOMDocument;
        $previous = libxml_use_internal_errors(true);
        $loaded = $document->loadHTML('<?xml encoding="UTF-8">'.$html, LIBXML_NONET | LIBXML_NOERROR | LIBXML_NOWARNING);
        libxml_clear_errors();
        libxml_use_internal_errors($previous);
        if (! $loaded) {
            throw new RuntimeException('MAGMA response is not parseable HTML.');
        }

        return new DOMXPath($document);
    }

    private function extractLevel(string $text): ?string
    {
        return preg_match('/Level\s+(I{1,3}|IV|[1-4])\s*\(([^)]+)\)/iu', $text, $match)
            ? 'Level '.strtoupper($match[1]).' ('.trim($match[2]).')'
            : null;
    }

    /** @param list<string> $labels */
    private function section(DOMXPath $xpath, array $labels): ?string
    {
        foreach ($labels as $label) {
            $nodes = $xpath->query('//*[self::h1 or self::h2 or self::h3 or self::h4 or self::strong or self::b]');
            foreach ($nodes ?: [] as $node) {
                if (mb_strtolower(trim($node->textContent)) !== mb_strtolower($label)) {
                    continue;
                }
                $candidate = $node->nextSibling;
                for ($i = 0; $candidate !== null && $i < 4; $i++, $candidate = $candidate->nextSibling) {
                    $text = trim(preg_replace('/\s+/u', ' ', $candidate->textContent) ?? '');
                    if ($text !== '') {
                        return mb_substr($text, 0, 10000);
                    }
                }
                $parent = trim(preg_replace('/\s+/u', ' ', $node->parentNode?->textContent ?? '') ?? '');
                if ($parent !== trim($node->textContent)) {
                    return mb_substr(trim(str_replace(trim($node->textContent), '', $parent)), 0, 10000) ?: null;
                }
            }
        }

        return null;
    }

    /** @return array{?float,?float} */
    private function coordinates(string $html): array
    {
        if (preg_match('/L\.marker\s*\(\s*\[\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)/i', $html, $match)) {
            $latitude = (float) $match[1];
            $longitude = (float) $match[2];
            if ($latitude >= -90 && $latitude <= 90 && $longitude >= -180 && $longitude <= 180) {
                return [$latitude, $longitude];
            }
        }

        return [null, null];
    }
}
