<?php

declare(strict_types=1);

/**
 * PHP API Stack - Comprehensive Health Check (Open Basedir Safe)
 * 
 * Production-ready with defensive programming for restricted environments.
 * Respects open_basedir and security constraints.
 * 
 * @link https://www.php.net/manual/en/ini.core.php#ini.open-basedir
 * @link https://www.php.net/manual/en/book.opcache.php
 * @link https://redis.io/docs/connect/clients/php/
 * 
 * HTTP Status Codes:
 * - 200: All systems healthy
 * - 503: One or more critical systems degraded
 * - 500: Internal error during health check
 */

namespace HealthCheck;

// ============================================================================
// INTERFACES (Dependency Inversion Principle)
// ============================================================================

interface HealthCheckInterface
{
    public function check(): CheckResult;
    public function getName(): string;
    public function isCritical(): bool;
}

// ============================================================================
// VALUE OBJECTS (Immutability)
// ============================================================================

final readonly class CheckResult
{
    public function __construct(
        public bool $healthy,
        public string $status,
        public array $details = [],
        public ?string $error = null,
        public ?float $duration = null
    ) {}

    public function toArray(): array
    {
        $result = [
            'healthy' => $this->healthy,
            'status' => $this->status,
        ];

        if (!empty($this->details)) {
            $result['details'] = $this->details;
        }

        if ($this->error !== null) {
            $result['error'] = $this->error;
        }

        if ($this->duration !== null) {
            $result['duration_ms'] = round($this->duration * 1000, 2);
        }

        return $result;
    }
}

// ============================================================================
// UTILITIES (DRY Principle)
// ============================================================================

final class ByteFormatter
{
    private const UNITS = ['B', 'KB', 'MB', 'GB'];

    public static function format(int $bytes): string
    {
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count(self::UNITS) - 1);
        $bytes /= (1 << (10 * $pow));

        return round($bytes, 2) . ' ' . self::UNITS[$pow];
    }
}

// ============================================================================
// ABSTRACT BASE CHECKER (Template Method Pattern)
// ============================================================================

abstract class AbstractHealthCheck implements HealthCheckInterface
{
    protected bool $critical = true;

    final public function check(): CheckResult
    {
        $start = microtime(true);

        try {
            $result = $this->performCheck();
            $duration = microtime(true) - $start;

            return new CheckResult(
                healthy: $result['healthy'],
                status: $result['status'],
                details: $result['details'] ?? [],
                error: $result['error'] ?? null,
                duration: $duration
            );
        } catch (\Throwable $e) {
            $duration = microtime(true) - $start;

            return new CheckResult(
                healthy: false,
                status: 'error',
                details: [],
                error: $e->getMessage(),
                duration: $duration
            );
        }
    }

    abstract protected function performCheck(): array;

    final public function isCritical(): bool
    {
        return $this->critical;
    }
}

// ============================================================================
// CONCRETE HEALTH CHECKERS (Single Responsibility Principle)
// ============================================================================

final class PhpRuntimeCheck extends AbstractHealthCheck
{
    public function getName(): string
    {
        return 'php';
    }

    protected function performCheck(): array
    {
        $memoryLimit = $this->parseMemory(ini_get('memory_limit'));
        $memoryUsage = memory_get_usage(true);
        $memoryPeakUsage = memory_get_peak_usage(true);
        $memoryUsagePercent = $memoryLimit > 0
            ? round(($memoryUsage / $memoryLimit) * 100, 2)
            : 0;

        $healthy = $memoryUsagePercent < 90;

        return [
            'healthy' => $healthy,
            'status' => $healthy ? 'healthy' : 'warning',
            'details' => [
                'version' => PHP_VERSION,
                'sapi' => PHP_SAPI,
                'memory' => [
                    'limit' => ByteFormatter::format($memoryLimit),
                    'usage' => ByteFormatter::format($memoryUsage),
                    'peak' => ByteFormatter::format($memoryPeakUsage),
                    'usage_percent' => $memoryUsagePercent,
                ],
                'zend_version' => zend_version(),
            ],
        ];
    }

    private function parseMemory(string $value): int
    {
        $value = trim($value);
        if ($value === '-1') {
            return PHP_INT_MAX;
        }

        $unit = strtolower($value[strlen($value) - 1]);
        $value = (int) $value;

        return match ($unit) {
            'g' => $value * 1024 * 1024 * 1024,
            'm' => $value * 1024 * 1024,
            'k' => $value * 1024,
            default => $value,
        };
    }
}

final class PhpExtensionsCheck extends AbstractHealthCheck
{
    protected bool $critical = false;

    private const REQUIRED_EXTENSIONS = ['pdo', 'mbstring', 'json', 'curl'];
    private const OPTIONAL_EXTENSIONS = ['redis', 'apcu', 'intl', 'zip', 'gd', 'xml'];

    public function getName(): string
    {
        return 'php_extensions';
    }

    protected function performCheck(): array
    {
        $loadedExtensions = get_loaded_extensions();
        $requiredLoaded = [];
        $requiredMissing = [];
        $optionalLoaded = [];

        foreach (self::REQUIRED_EXTENSIONS as $ext) {
            if (extension_loaded($ext)) {
                $requiredLoaded[] = $ext;
            } else {
                $requiredMissing[] = $ext;
            }
        }

        foreach (self::OPTIONAL_EXTENSIONS as $ext) {
            if (extension_loaded($ext)) {
                $optionalLoaded[] = $ext;
            }
        }

        $healthy = empty($requiredMissing);

        return [
            'healthy' => $healthy,
            'status' => $healthy ? 'healthy' : 'critical',
            'details' => [
                'total_loaded' => count($loadedExtensions),
                'required' => [
                    'loaded' => $requiredLoaded,
                    'missing' => $requiredMissing,
                ],
                'optional_loaded' => $optionalLoaded,
            ],
            'error' => !$healthy ? 'Missing required extensions: ' . implode(', ', $requiredMissing) : null,
        ];
    }
}

final class OpcacheCheck extends AbstractHealthCheck
{
    protected bool $critical = false;

    private const MIN_HIT_RATE = 90.0;
    private const MAX_MEMORY_USAGE = 90.0;

    public function getName(): string
    {
        return 'opcache';
    }

    protected function performCheck(): array
    {
        if (!function_exists('opcache_get_status')) {
            return [
                'healthy' => false,
                'status' => 'unavailable',
                'details' => [],
                'error' => 'OPcache extension not available',
            ];
        }

        $status = @opcache_get_status(false);

        if ($status === false) {
            return [
                'healthy' => false,
                'status' => 'disabled',
                'details' => [],
                'error' => 'OPcache is disabled',
            ];
        }

        $memoryUsed = $status['memory_usage']['used_memory'] ?? 0;
        $memoryFree = $status['memory_usage']['free_memory'] ?? 0;
        $memoryTotal = $memoryUsed + $memoryFree;
        $memoryUsagePercent = $memoryTotal > 0
            ? round(($memoryUsed / $memoryTotal) * 100, 2)
            : 0;

        $hits = $status['opcache_statistics']['hits'] ?? 0;
        $misses = $status['opcache_statistics']['misses'] ?? 0;
        $total = $hits + $misses;
        $hitRate = $total > 0 ? round(($hits / $total) * 100, 2) : 0;

        $healthy = $hitRate >= self::MIN_HIT_RATE && $memoryUsagePercent < self::MAX_MEMORY_USAGE;

        return [
            'healthy' => $healthy,
            'status' => $healthy ? 'healthy' : 'warning',
            'details' => [
                'enabled' => true,
                'memory' => [
                    'used' => ByteFormatter::format($memoryUsed),
                    'free' => ByteFormatter::format($memoryFree),
                    'usage_percent' => $memoryUsagePercent,
                    'wasted_percent' => round($status['memory_usage']['current_wasted_percentage'] ?? 0, 2),
                ],
                'statistics' => [
                    'hits' => $hits,
                    'misses' => $misses,
                    'hit_rate' => $hitRate,
                    'cached_scripts' => $status['opcache_statistics']['num_cached_scripts'] ?? 0,
                    'max_cached_keys' => $status['opcache_statistics']['max_cached_keys'] ?? 0,
                ],
                'jit' => [
                    'enabled' => $status['jit']['enabled'] ?? false,
                    'on' => $status['jit']['on'] ?? false,
                    'buffer_size' => ByteFormatter::format($status['jit']['buffer_size'] ?? 0),
                ],
                'restarts' => [
                    'oom' => $status['opcache_statistics']['oom_restarts'] ?? 0,
                    'hash' => $status['opcache_statistics']['hash_restarts'] ?? 0,
                    'manual' => $status['opcache_statistics']['manual_restarts'] ?? 0,
                ],
            ],
        ];
    }
}

final class RedisCheck extends AbstractHealthCheck
{
    protected bool $critical = false;

    private const TIMEOUT = 1.0;
    private const MAX_LATENCY_MS = 100.0;

    public function getName(): string
    {
        return 'redis';
    }

    protected function performCheck(): array
    {
        if (!extension_loaded('redis')) {
            return [
                'healthy' => false,
                'status' => 'unavailable',
                'details' => [],
                'error' => 'Redis extension not installed',
            ];
        }

        $redis = new \Redis();

        $host = getenv('REDIS_HOST') ?: '127.0.0.1';
        $password = getenv('REDIS_PASSWORD') ?: null;
        $port = getenv('REDIS_PORT') ?: 6379;


        try {
            $connectStart = microtime(true);
            $connected = @$redis->connect('127.0.0.1', $port, self::TIMEOUT);
            $connectDuration = (microtime(true) - $connectStart) * 1000;

            if (!$connected) {
                return [
                    'healthy' => false,
                    'status' => 'unavailable',
                    'details' => [
                        'connect_latency_ms' => round($connectDuration, 2),
                    ],
                    'error' => 'Cannot connect to Redis',
                ];
            }

            if ($password !== null && $password !== '') {
                if (!@$redis->auth($password)) {
                    return [
                        'healthy' => false,
                        'status' => 'unauthenticated',
                        'details' => ['host' => $host],
                        'error' => 'Redis authentication failed (NOAUTH). Check REDIS_PASSWORD.',
                    ];
                }
            }

            $pingStart = microtime(true);
            $pong = $redis->ping();
            $pingDuration = (microtime(true) - $pingStart) * 1000;

            if ($pong !== true && $pong !== '+PONG') {
                throw new \RuntimeException('Redis ping failed');
            }

            $info = $redis->info();
            $healthy = $pingDuration < self::MAX_LATENCY_MS;

            return [
                'healthy' => $healthy,
                'status' => $healthy ? 'healthy' : 'warning',
                'details' => [
                    'connected' => true,
                    'version' => $info['redis_version'] ?? 'unknown',
                    'uptime_seconds' => (int) ($info['uptime_in_seconds'] ?? 0),
                    'memory' => [
                        'used' => $info['used_memory_human'] ?? 'unknown',
                        'peak' => $info['used_memory_peak_human'] ?? 'unknown',
                        'fragmentation_ratio' => (float) ($info['mem_fragmentation_ratio'] ?? 0),
                    ],
                    'stats' => [
                        'connected_clients' => (int) ($info['connected_clients'] ?? 0),
                        'total_commands_processed' => (int) ($info['total_commands_processed'] ?? 0),
                        'keyspace_hits' => (int) ($info['keyspace_hits'] ?? 0),
                        'keyspace_misses' => (int) ($info['keyspace_misses'] ?? 0),
                    ],
                    'latency' => [
                        'connect_ms' => round($connectDuration, 2),
                        'ping_ms' => round($pingDuration, 2),
                    ],
                ],
            ];
        } catch (\Throwable $e) {
            return [
                'healthy' => false,
                'status' => 'error',
                'details' => [],
                'error' => $e->getMessage(),
            ];
        } finally {
            @$redis->close();
        }
    }
}

/**
 * System Resources Check - Defensive Programming
 * 
 * Gracefully handles open_basedir restrictions by using fallback strategies.
 * 
 * @link https://www.php.net/manual/en/ini.core.php#ini.open-basedir
 */
final class SystemResourcesCheck extends AbstractHealthCheck
{
    protected bool $critical = false;

    private const MAX_DISK_USAGE = 90.0;
    private const MAX_LOAD_AVERAGE = 10.0;

    public function getName(): string
    {
        return 'system';
    }

    protected function performCheck(): array
    {
        $diskFree = @disk_free_space('/');
        $diskTotal = @disk_total_space('/');
        $diskUsagePercent = $diskTotal > 0
            ? round((($diskTotal - $diskFree) / $diskTotal) * 100, 2)
            : 0;

        $loadAvg = @sys_getloadavg();
        $load1 = $loadAvg[0] ?? 0;

        $memoryInfo = $this->getMemoryInfoSafely();

        $healthy = $diskUsagePercent < self::MAX_DISK_USAGE && $load1 < self::MAX_LOAD_AVERAGE;

        return [
            'healthy' => $healthy,
            'status' => $healthy ? 'healthy' : 'warning',
            'details' => [
                'disk' => [
                    'total' => ByteFormatter::format($diskTotal ?: 0),
                    'free' => ByteFormatter::format($diskFree ?: 0),
                    'usage_percent' => $diskUsagePercent,
                ],
                'load_average' => [
                    '1min' => round($load1, 2),
                    '5min' => round($loadAvg[1] ?? 0, 2),
                    '15min' => round($loadAvg[2] ?? 0, 2),
                ],
                'memory' => $memoryInfo,
            ],
        ];
    }

    /**
     * Safely reads memory info with fallback strategy.
     * 
     * Strategy 1: Try /proc/meminfo (full system memory)
     * Strategy 2: Fallback to PHP memory usage (if restricted)
     */
    private function getMemoryInfoSafely(): array
    {
        set_error_handler(static fn() => true);
        $content = @file_get_contents('/proc/meminfo');
        restore_error_handler();

        if ($content === false) {
            return [
                'source' => 'php_fallback',
                'note' => 'System memory unavailable (open_basedir restriction)',
                'php_memory_usage' => ByteFormatter::format(memory_get_usage(true)),
                'php_memory_peak' => ByteFormatter::format(memory_get_peak_usage(true)),
            ];
        }

        $matches = [];
        preg_match_all('/^(\w+):\s+(\d+)\s+kB/m', $content, $matches, PREG_SET_ORDER);

        $meminfo = [];
        foreach ($matches as $match) {
            $meminfo[$match[1]] = (int) $match[2] * 1024;
        }

        $memTotal = $meminfo['MemTotal'] ?? 0;
        $memAvailable = $meminfo['MemAvailable'] ?? $meminfo['MemFree'] ?? 0;
        $memUsed = $memTotal - $memAvailable;
        $memUsagePercent = $memTotal > 0 ? round(($memUsed / $memTotal) * 100, 2) : 0;

        return [
            'source' => 'proc_meminfo',
            'total' => ByteFormatter::format($memTotal),
            'available' => ByteFormatter::format($memAvailable),
            'used' => ByteFormatter::format($memUsed),
            'usage_percent' => $memUsagePercent,
        ];
    }
}

/**
 * Application Check - Respects Open Basedir
 * 
 * Only checks directories within open_basedir scope.
 * Provides clear feedback about security restrictions.
 */
final class ApplicationCheck extends AbstractHealthCheck
{
    protected bool $critical = false;

    /**
     * CRITICAL: Only check paths within typical open_basedir scope.
     * 
     * Common open_basedir: /var/www/html:/tmp:/usr/local/lib/php:/usr/share/php
     * 
     * Excluded: /var/log/* (security policy prevents access)
     */
    private const ACCESSIBLE_DIRS = [
        '/var/www/html',
        '/var/www/html/public',
        '/tmp',
    ];

    public function getName(): string
    {
        return 'application';
    }

    protected function performCheck(): array
    {
        $directoryStatus = [];
        $allHealthy = true;
        $openBasedir = ini_get('open_basedir');

        foreach (self::ACCESSIBLE_DIRS as $dir) {
            $status = $this->checkDirectorySafely($dir);
            $directoryStatus[basename($dir)] = $status;

            if (!$status['exists'] || !$status['readable']) {
                $allHealthy = false;
            }
        }

        $details = [
            'directories' => $directoryStatus,
            'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? 'unknown',
        ];

        // Add informational note about security policy
        if (!empty($openBasedir)) {
            $details['security_note'] = 'Log directories (/var/log) excluded per open_basedir policy';
            $details['open_basedir'] = $openBasedir;
        }

        return [
            'healthy' => $allHealthy,
            'status' => $allHealthy ? 'healthy' : 'warning',
            'details' => $details,
        ];
    }

    /**
     * Defensive directory check with error suppression.
     * 
     * Prevents warnings when open_basedir blocks access.
     */
    private function checkDirectorySafely(string $path): array
    {
        set_error_handler(static fn() => true);

        $exists = @is_dir($path);
        $readable = $exists && @is_readable($path);
        $writable = $exists && @is_writable($path);

        restore_error_handler();

        return [
            'path' => $path,
            'exists' => $exists,
            'readable' => $readable,
            'writable' => $writable,
        ];
    }
}

// ============================================================================
// HEALTH CHECK MANAGER (Facade Pattern)
// ============================================================================

final class HealthCheckManager
{
    /** @var array<string, HealthCheckInterface> */
    private array $checkers = [];

    public function addChecker(HealthCheckInterface $checker): self
    {
        $this->checkers[$checker->getName()] = $checker;
        return $this;
    }

    public function runAll(): array
    {
        $startTime = microtime(true);
        $results = [];
        $overallHealthy = true;

        foreach ($this->checkers as $name => $checker) {
            $result = $checker->check();
            $results[$name] = $result->toArray();

            if (!$result->healthy && $checker->isCritical()) {
                $overallHealthy = false;
            }
        }

        $duration = microtime(true) - $startTime;

        return [
            'status' => $overallHealthy ? 'healthy' : 'unhealthy',
            'timestamp' => date('c'),
            'duration_ms' => round($duration * 1000, 2),
            'checks' => $results,
        ];
    }
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

try {
    $manager = new HealthCheckManager();

    $manager
        ->addChecker(new PhpRuntimeCheck())
        ->addChecker(new PhpExtensionsCheck())
        ->addChecker(new OpcacheCheck())
        ->addChecker(new RedisCheck())
        ->addChecker(new SystemResourcesCheck())
        ->addChecker(new ApplicationCheck());

    $health = $manager->runAll();

    $statusCode = $health['status'] === 'healthy' ? 200 : 503;
    http_response_code($statusCode);

    echo json_encode($health, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
} catch (\Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'timestamp' => date('c'),
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
    ], JSON_PRETTY_PRINT);
}
