<?php
// lib/http.php

function input_json(): array {
  $raw = file_get_contents('php://input');
  if (!$raw) return [];
  $data = json_decode($raw, true);
  return is_array($data) ? $data : [];
}

function query($key, $default=null) {
  return $_GET[$key] ?? $default;
}

function json_ok($data = [], int $code = 200) {
  http_response_code($code);
  echo json_encode(['ok' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
  exit;
}

function json_err(string $code, string $message = '', array $details = [], int $http = 400) {
  http_response_code($http);
  echo json_encode(['ok' => false, 'error' => $code, 'message' => $message, 'details' => $details], JSON_UNESCAPED_UNICODE);
  exit;
}

function not_found() { json_err('NOT_FOUND', 'Endpoint not found', [], 404); }

function require_fields(array $body, array $fields) {
  foreach ($fields as $f) {
    if (!array_key_exists($f, $body) || $body[$f] === '' || $body[$f] === null) {
      json_err('VALIDATION_FAILED', "Missing field: $f", ['field' => $f], 422);
    }
  }
}
