<?php

/**
 * @file
 * Enables modules and site configuration for a civicrm site installation.
 */

/**
 * Implements hook_install_tasks().
 */
function civicrmprofile_install_tasks($install_state){
  $tasks = array(
    'civicrmprofile_permissions' => array(
      'display_name' => st('Permissions'),
      'display' => FALSE,
      'type' => 'normal'
    ),
  );
  return $tasks;
}

/**
 * Install task to configure CRM permissions.
 * Only Drupal core permissions are set here
 */
function civicrmprofile_permissions() {
  // drush_log('civicrmprofile d():' . print_r(d(), 1), 'debug');
  $context = d()->context_type;

  if ($context === "platform") {
    // platform install, do nothing
    drush_log('civicrmprofile_permissions() platform install, do nothing' , 'notice');

  } elseif ($context === "site") {
    // CRM site install
    drush_log('civicrmprofile_permissions() site install' , 'notice');

    // 1) Anonymous users
    // used for users that don't have a user account or that are not authenticated
    user_role_grant_permissions(DRUPAL_ANONYMOUS_RID, array(
     'access content',
    ));

    // 2) Authenticated users
    // this role is automatically granted to all logged in users
    user_role_grant_permissions(DRUPAL_AUTHENTICATED_RID, array(
      'access content',
      'change own username',
      'cancel account',
      'setup own tfa',
    ));

    // 3) Administrators
    // the role for site administrators, with all available permissions assigned.
    user_role_grant_permissions(variable_get('user_admin_role'), array_keys(module_invoke_all('permission')));

    // 4) Permissions for CRM users
    $role = user_role_load_by_name('crm user');
    user_role_grant_permissions($role->rid, array(
      'access content',
    ));

    // 5) Permissions for super users
    $role = user_role_load_by_name('super user');
    user_role_grant_permissions($role->rid, array(
      'administer users',
      'assign crm user role',
      'assign super user role',
      'assign crm coord role',
      'assign crm comm role',
      'assign crm analyst role',
    ));

    // 6) Permissions for CRM admins
    $role = user_role_load_by_name('crm admin');
    user_role_grant_permissions($role->rid, array(
      'administer users',
      'assign crm user role',
      'assign super user role',
      'assign crm admin role',
      'assign crm coord role',
      'assign crm comm role',
      'assign crm analyst role',
    ));

  } else {
     // something is wrong...
     drush_log('wrong context in civicrmprofile_permissions(): ' . $context, 'warning');
  }
}

/**
 * block_info hook: information schema for block
 */
function civicrmprofile_block_info() {
  $blocks = array();
  $blocks['crm-user-menu'] = array (
    'info'       => t('CRM menü'),
    'region'     => 'sidebar_first',
    'status'     => TRUE,
    'visibility' => BLOCK_VISIBILITY_LISTED,
    'pages'      => '<front>',
  );
  $blocks['crm-admin-menu'] = array (
    'info'  => t('CRM admin'),
    'region'     => 'sidebar_first',
    'status'     => TRUE,
    'visibility' => BLOCK_VISIBILITY_LISTED,
    'pages'      => '<front>',
  );
  $blocks['crm-superuser-menu'] = array (
    'info'  => t('CRM superuser'),
    'region'     => 'sidebar_first',
    'status'     => TRUE,
    'visibility' => BLOCK_VISIBILITY_LISTED,
    'pages'      => '<front>',
  );
  $blocks['crm-campaign-menu'] = array (
    'info'  => t('Campaign tools'),
    'region'     => 'sidebar_first',
    'status'     => TRUE,
    'visibility' => BLOCK_VISIBILITY_LISTED,
    'pages'      => '<front>',
  );
  return $blocks;
}

/**
 * block_view hook to set content for block and to make it visible
 */
function civicrmprofile_block_view($delta='') {
  $block = array();
  global $user;
  switch ($delta) {
    case 'crm-user-menu':
      if (in_array('crm user', $user->roles)) {
        $block['subject'] = t('CRM menü');
        $block['content'] = _crmusermenu_content();
      }
      break;
    case 'crm-admin-menu':
      if (in_array('crm admin', $user->roles)) {
        $block['subject'] = t('CRM admin');
        $block['content'] = _crmadminmenu_content();
      }
      break;
    case 'crm-superuser-menu':
      if (in_array('super user', $user->roles)) {
        $block['subject'] = t('CRM superuser');
        $block['content'] = _superusermenu_content();
      }
      break;
    case 'crm-campaign-menu':
      if (in_array('crm coord', $user->roles)) {
        $block['subject'] = t('Campaign tools');
        $block['content'] = _campaignmenu_content();
      }
      break;
  }
  return $block;
}

/**
 * block content for CRM user menu block
 */
function _crmusermenu_content() {
  $content = array();
  $content = _add_to_blockcontents($content, 'Kapcsolat keresés', '/civicrm/contact/search?reset=1');
  $content = _add_to_blockcontents($content, 'Részletes keresés', '/civicrm/contact/search/advanced?reset=1');
  $content = _add_to_blockcontents($content, 'Új kapcsolat', '/civicrm/contact/add?reset=1&ct=Individual');
  $content = _add_to_blockcontents($content, 'Új aktivitás', '/civicrm/activity?reset=1&action=add&context=standalone');
  $content = _add_to_blockcontents($content, 'Körlevél', '/civicrm/mailing/browse/scheduled');
  $content = _add_to_blockcontents($content, 'Ügyek', '/civicrm/case');
  $content = _add_to_blockcontents($content, 'Riportok', '/civicrm/report/list?compid=4&reset=1');
  return $content;
}

/**
 * block content for site admin menu block
 */
function _crmadminmenu_content() {
  $content = array();
  $content = _add_to_blockcontents($content, 'CRM admin', '/civicrm/admin');
  $content = _add_to_blockcontents($content, 'Felhasználók', '/admin/people');
  return $content;
}

/**
 * block content for superuser menu block
 */
function _superusermenu_content() {
  $content = array();
  $content = _add_to_blockcontents($content, 'Csoportok', '/civicrm/group');
  $content = _add_to_blockcontents($content, 'Címkék', '/civicrm/tag');
  $content = _add_to_blockcontents($content, 'Kapcsolat import', '/civicrm/import/contact');
  $content = _add_to_blockcontents($content, 'Felhasználók', '/admin/people');
  return $content;
}

/**
 * block content for campaign menu blocks
 */
function _campaignmenu_content() {
  $content = array();
  $content = _add_to_blockcontents($content, 'Események', '/civicrm/event');
  $content = _add_to_blockcontents($content, 'Kampányok', '/civicrm/campaign?reset=1');
  return $content;
}

/**
 * block content for CRM user menu block
 */
function _add_to_blockcontents($content, $title, $link) {
  $fixes =  array(
    '#prefix' => '<p>',
    '#suffix' => '</p>',
  );
  $newline = array(
    '#markup' => l($title, $link),
  );
  array_push($content, $fixes + $newline);
  return $content;
}
