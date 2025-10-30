<?php
// controllers/ModifiersController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/ModifiersRepo.php';

class ModifiersController {
  public static function groups() {
    need_role(['admin']);
    $groups = ModifiersRepo::listGroups();
    json_ok($groups);
  }

  public static function createGroup() {
    need_role(['admin']);
    $body = input_json();
    require_fields($body, ['name']);
    $id = ModifiersRepo::insertGroup($body);
    json_ok(['id' => $id], 201);
  }

  public static function updateGroup($id) {
    need_role(['admin']);
    $body = input_json();
    require_fields($body, ['name']);
    if (!ModifiersRepo::getGroup((int)$id)) {
      json_err('NOT_FOUND', 'Modifier group not found', [], 404);
    }
    ModifiersRepo::updateGroup((int)$id, $body);
    json_ok(['id' => (int)$id]);
  }

  public static function deleteGroup($id) {
    need_role(['admin']);
    if (!ModifiersRepo::getGroup((int)$id)) {
      json_err('NOT_FOUND', 'Modifier group not found', [], 404);
    }
    ModifiersRepo::deleteGroup((int)$id);
    json_ok(['id' => (int)$id]);
  }

  public static function options($groupId) {
    need_role(['admin']);
    if (!ModifiersRepo::getGroup((int)$groupId)) {
      json_err('NOT_FOUND', 'Modifier group not found', [], 404);
    }
    $options = ModifiersRepo::listOptions((int)$groupId);
    json_ok($options);
  }

  public static function createOption($groupId) {
    need_role(['admin']);
    if (!ModifiersRepo::getGroup((int)$groupId)) {
      json_err('NOT_FOUND', 'Modifier group not found', [], 404);
    }
    $body = input_json();
    require_fields($body, ['name']);
    $id = ModifiersRepo::insertOption((int)$groupId, $body);
    json_ok(['id' => $id], 201);
  }

  public static function updateOption($optionId) {
    need_role(['admin']);
    $body = input_json();
    require_fields($body, ['name']);
    ModifiersRepo::updateOption((int)$optionId, $body);
    json_ok(['id' => (int)$optionId]);
  }

  public static function deleteOption($optionId) {
    need_role(['admin']);
    ModifiersRepo::deleteOption((int)$optionId);
    json_ok(['id' => (int)$optionId]);
  }

  public static function itemGroups($itemId) {
    need_role(['admin']);
    $groups = ModifiersRepo::listItemGroups((int)$itemId);
    json_ok($groups);
  }

  public static function setItemGroups($itemId) {
    need_role(['admin']);
    $body = input_json();
    $groupIds = $body['group_ids'] ?? [];
    if (!is_array($groupIds)) {
      json_err('VALIDATION_FAILED', 'group_ids must be an array', [], 422);
    }
    $normalized = array_values(array_unique(array_map('intval', $groupIds)));
    ModifiersRepo::replaceItemGroups((int)$itemId, $normalized);
    json_ok(['item_id' => (int)$itemId, 'group_ids' => $normalized]);
  }
}
