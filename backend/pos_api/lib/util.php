<?php
// lib/util.php

function str_or_null($v) { return $v === '' ? null : $v; }

function make_receipt_no(int $orderId): string {
  return 'RCP-' . date('Ymd') . '-' . $orderId;
}

function sanitize_filename($name): string {
  return preg_replace('/[^A-Za-z0-9_\-\.]/', '_', $name);
}
