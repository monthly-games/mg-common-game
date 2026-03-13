import 'dart:async';
import 'package:flutter/material.dart';

enum Permission {
  userRead,
  userWrite,
  userDelete,
  contentRead,
  contentWrite,
  contentDelete,
  adminRead,
  adminWrite,
  adminDelete,
  pvpPlay,
  pvpOrganize,
  guildCreate,
  guildManage,
  guildDelete,
  chatRead,
  chatWrite,
  chatModerate,
  economyRead,
  economySpend,
  economyManage,
}

enum RoleType {
  guest,
  user,
  moderator,
  admin,
  superAdmin,
}

class Role {
  final String roleId;
  final String name;
  final String description;
  final RoleType type;
  final Set<Permission> permissions;
  final int priority;
  final DateTime createdAt;

  const Role({
    required this.roleId,
    required this.name,
    required this.description,
    required this.type,
    required this.permissions,
    required this.priority,
    required this.createdAt,
  });

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }
}

class Resource {
  final String resourceId;
  final String type;
  final String ownerId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const Resource({
    required this.resourceId,
    required this.type,
    required this.ownerId,
    required this.metadata,
    required this.createdAt,
  });
}

class AccessPolicy {
  final String policyId;
  final String name;
  final String resourceType;
  final Set<Permission> requiredPermissions;
  final Map<String, dynamic> conditions;

  const AccessPolicy({
    required this.policyId,
    required this.name,
    required this.resourceType,
    required this.requiredPermissions,
    required this.conditions,
  });

  bool evaluate(Map<String, dynamic> context) {
    for (final entry in conditions.entries) {
      final contextValue = context[entry.key];
      final requiredValue = entry.value;

      if (contextValue != requiredValue) {
        return false;
      }
    }
    return true;
  }
}

class UserPermission {
  final String userId;
  final Set<Permission> permissions;
  final Set<String> roleIds;
  final Map<String, DateTime> expirations;
  final DateTime updatedAt;

  const UserPermission({
    required this.userId,
    required this.permissions,
    required this.roleIds,
    required this.expirations,
    required this.updatedAt,
  });

  bool hasPermission(Permission permission) {
    if (permissions.contains(permission)) {
      final expiration = expirations[permission.toString()];
      if (expiration == null) return true;
      return DateTime.now().isBefore(expiration);
    }
    return false;
  }
}

class AccessLog {
  final String logId;
  final String userId;
  final String resource;
  final Permission permission;
  final bool granted;
  final String? reason;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const AccessLog({
    required this.logId,
    required this.userId,
    required this.resource,
    required this.permission,
    required this.granted,
    this.reason,
    required this.timestamp,
    this.metadata,
  });
}

class AuthorizationManager {
  static final AuthorizationManager _instance = AuthorizationManager._();
  static AuthorizationManager get instance => _instance;

  AuthorizationManager._();

  final Map<String, Role> _roles = {};
  final Map<String, UserPermission> _userPermissions = {};
  final Map<String, AccessPolicy> _policies = {};
  final List<AccessLog> _accessLogs = [];
  final StreamController<AuthorizationEvent> _eventController = StreamController.broadcast();

  Stream<AuthorizationEvent> get onAuthzEvent => _eventController.stream;

  void initialize() {
    _createDefaultRoles();
    _createDefaultPolicies();
  }

  void _createDefaultRoles() {
    final guestRole = Role(
      roleId: 'role_guest',
      name: 'Guest',
      description: 'Guest user with limited permissions',
      type: RoleType.guest,
      permissions: {
        Permission.contentRead,
        Permission.chatRead,
      },
      priority: 0,
      createdAt: DateTime.now(),
    );

    final userRole = Role(
      roleId: 'role_user',
      name: 'User',
      description: 'Regular user permissions',
      type: RoleType.user,
      permissions: {
        Permission.userRead,
        Permission.userWrite,
        Permission.contentRead,
        Permission.contentWrite,
        Permission.pvpPlay,
        Permission.guildCreate,
        Permission.chatRead,
        Permission.chatWrite,
        Permission.economyRead,
        Permission.economySpend,
      },
      priority: 1,
      createdAt: DateTime.now(),
    );

    final moderatorRole = Role(
      roleId: 'role_moderator',
      name: 'Moderator',
      description: 'Moderator permissions',
      type: RoleType.moderator,
      permissions: {
        Permission.userRead,
        Permission.contentRead,
        Permission.contentDelete,
        Permission.chatRead,
        Permission.chatWrite,
        Permission.chatModerate,
        Permission.economyRead,
        Permission.pvpOrganize,
        Permission.guildManage,
      },
      priority: 2,
      createdAt: DateTime.now(),
    );

    final adminRole = Role(
      roleId: 'role_admin',
      name: 'Admin',
      description: 'Administrator permissions',
      type: RoleType.admin,
      permissions: {
        Permission.userRead,
        Permission.userWrite,
        Permission.userDelete,
        Permission.contentRead,
        Permission.contentWrite,
        Permission.contentDelete,
        Permission.adminRead,
        Permission.adminWrite,
        Permission.pvpPlay,
        Permission.pvpOrganize,
        Permission.guildCreate,
        Permission.guildManage,
        Permission.guildDelete,
        Permission.chatRead,
        Permission.chatWrite,
        Permission.chatModerate,
        Permission.economyRead,
        Permission.economySpend,
        Permission.economyManage,
      },
      priority: 3,
      createdAt: DateTime.now(),
    );

    final superAdminRole = Role(
      roleId: 'role_super_admin',
      name: 'Super Admin',
      description: 'Super administrator with all permissions',
      type: RoleType.superAdmin,
      permissions: Permission.values.toSet(),
      priority: 4,
      createdAt: DateTime.now(),
    );

    _roles[guestRole.roleId] = guestRole;
    _roles[userRole.roleId] = userRole;
    _roles[moderatorRole.roleId] = moderatorRole;
    _roles[adminRole.roleId] = adminRole;
    _roles[superAdminRole.roleId] = superAdminRole;
  }

  void _createDefaultPolicies() {
    final userPolicy = AccessPolicy(
      policyId: 'policy_user',
      name: 'User Resource Policy',
      resourceType: 'user',
      requiredPermissions: {Permission.userRead},
      conditions: {'owner_only': true},
    );

    final contentPolicy = AccessPolicy(
      policyId: 'policy_content',
      name: 'Content Resource Policy',
      resourceType: 'content',
      requiredPermissions: {Permission.contentRead},
      conditions: {'public': true},
    );

    _policies[userPolicy.policyId] = userPolicy;
    _policies[contentPolicy.policyId] = contentPolicy;
  }

  Role? getRole(String roleId) {
    return _roles[roleId];
  }

  List<Role> getAllRoles() {
    return _roles.values.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  Future<bool> assignRole({
    required String userId,
    required String roleId,
  }) async {
    final role = _roles[roleId];
    if (role == null) return false;

    final userPerm = _userPermissions[userId] ?? UserPermission(
      userId: userId,
      permissions: {},
      roleIds: {},
      expirations: {},
      updatedAt: DateTime.now(),
    );

    final updated = UserPermission(
      userId: userId,
      permissions: userPerm.permissions,
      roleIds: {...userPerm.roleIds, roleId},
      expirations: userPerm.expirations,
      updatedAt: DateTime.now(),
    );

    _userPermissions[userId] = updated;

    _eventController.add(AuthorizationEvent(
      type: AuthzEventType.roleAssigned,
      userId: userId,
      data: {'roleId': roleId},
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> removeRole({
    required String userId,
    required String roleId,
  }) async {
    final userPerm = _userPermissions[userId];
    if (userPerm == null) return false;

    final updated = UserPermission(
      userId: userId,
      permissions: userPerm.permissions,
      roleIds: userPerm.roleIds..remove(roleId),
      expirations: userPerm.expirations,
      updatedAt: DateTime.now(),
    );

    _userPermissions[userId] = updated;

    _eventController.add(AuthorizationEvent(
      type: AuthzEventType.roleRemoved,
      userId: userId,
      data: {'roleId': roleId},
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> grantPermission({
    required String userId,
    required Permission permission,
    DateTime? expiration,
  }) async {
    final userPerm = _userPermissions[userId] ?? UserPermission(
      userId: userId,
      permissions: {},
      roleIds: {},
      expirations: {},
      updatedAt: DateTime.now(),
    );

    final updated = UserPermission(
      userId: userId,
      permissions: {...userPerm.permissions, permission},
      roleIds: userPerm.roleIds,
      expirations: expiration != null
          ? {...userPerm.expirations, permission.toString(): expiration}
          : userPerm.expirations,
      updatedAt: DateTime.now(),
    );

    _userPermissions[userId] = updated;

    _eventController.add(AuthorizationEvent(
      type: AuthzEventType.permissionGranted,
      userId: userId,
      data: {'permission': permission.toString()},
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> revokePermission({
    required String userId,
    required Permission permission,
  }) async {
    final userPerm = _userPermissions[userId];
    if (userPerm == null) return false;

    final updated = UserPermission(
      userId: userId,
      permissions: userPerm.permissions..remove(permission),
      roleIds: userPerm.roleIds,
      expirations: userPerm.expirations,
      updatedAt: DateTime.now(),
    );

    _userPermissions[userId] = updated;

    _eventController.add(AuthorizationEvent(
      type: AuthzEventType.permissionRevoked,
      userId: userId,
      data: {'permission': permission.toString()},
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> checkPermission({
    required String userId,
    required Permission permission,
    String? resourceId,
    Map<String, dynamic>? context,
  }) async {
    final userPerm = _userPermissions[userId];

    if (userPerm != null) {
      if (userPerm.hasPermission(permission)) {
        _logAccess(
          userId: userId,
          resource: resourceId ?? 'unknown',
          permission: permission,
          granted: true,
        );
        return true;
      }
    }

    final hasRolePermission = await _checkRolePermission(
      userId: userId,
      permission: permission,
    );

    if (hasRolePermission) {
      _logAccess(
        userId: userId,
        resource: resourceId ?? 'unknown',
        permission: permission,
        granted: true,
      );
      return true;
    }

    _logAccess(
      userId: userId,
      resource: resourceId ?? 'unknown',
      permission: permission,
      granted: false,
      reason: 'Permission denied',
    );

    return false;
  }

  Future<bool> _checkRolePermission({
    required String userId,
    required Permission permission,
  }) async {
    final userPerm = _userPermissions[userId];
    if (userPerm == null) return false;

    for (final roleId in userPerm.roleIds) {
      final role = _roles[roleId];
      if (role != null && role.hasPermission(permission)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> checkAccess({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    final policy = _policies.values
        .where((p) => p.resourceType == resourceType)
        .firstOrNull;

    if (policy == null) {
      _logAccess(
        userId: userId,
        resource: resourceId,
        permission: Permission.userRead,
        granted: false,
        reason: 'No policy found',
      );
      return false;
    }

    final contextWithOwner = {
      'resourceId': resourceId,
      ...?context,
    };

    if (!policy.evaluate(contextWithOwner)) {
      _logAccess(
        userId: userId,
        resource: resourceId,
        permission: policy.requiredPermissions.first,
        granted: false,
        reason: 'Policy conditions not met',
      );
      return false;
    }

    for (final permission in policy.requiredPermissions) {
      final hasPermission = await checkPermission(
        userId: userId,
        permission: permission,
        resourceId: resourceId,
        context: contextWithOwner,
      );

      if (!hasPermission) {
        return false;
      }
    }

    return true;
  }

  void _logAccess({
    required String userId,
    required String resource,
    required Permission permission,
    required bool granted,
    String? reason,
  }) {
    final log = AccessLog(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      resource: resource,
      permission: permission,
      granted: granted,
      reason: reason,
      timestamp: DateTime.now(),
    );

    _accessLogs.add(log);

    _eventController.add(AuthorizationEvent(
      type: granted ? AuthzEventType.accessGranted : AuthzEventType.accessDenied,
      userId: userId,
      data: {
        'resource': resource,
        'permission': permission.toString(),
        'reason': reason,
      },
      timestamp: DateTime.now(),
    ));
  }

  List<AccessLog> getAccessLogs({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    var logs = _accessLogs.toList();

    if (userId != null) {
      logs = logs.where((log) => log.userId == userId).toList();
    }

    if (startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList();
  }

  Set<Permission> getUserPermissions(String userId) {
    final userPerm = _userPermissions[userId];
    if (userPerm == null) return {};

    final permissions = <Permission>{};
    permissions.addAll(userPerm.permissions);

    for (final roleId in userPerm.roleIds) {
      final role = _roles[roleId];
      if (role != null) {
        permissions.addAll(role.permissions);
      }
    }

    return permissions;
  }

  void dispose() {
    _eventController.close();
  }
}

class AuthorizationEvent {
  final AuthzEventType type;
  final String? userId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const AuthorizationEvent({
    required this.type,
    this.userId,
    this.data,
    required this.timestamp,
  });
}

enum AuthzEventType {
  roleAssigned,
  roleRemoved,
  permissionGranted,
  permissionRevoked,
  accessGranted,
  accessDenied,
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
