from .devices import (
    list_device_tokens_for_user,
    register_device_token,
    unregister_device_token,
)
from .push import send_push_notification_to_user
from .repository import (
    create_admin_notification,
    create_notification,
    create_user_notification,
    list_notifications,
    mark_all_notifications_read,
    mark_notification_read,
    unread_notification_count,
)


class NotificationMigrationError(RuntimeError):
    """Kept for compatibility with older callers of this module."""
