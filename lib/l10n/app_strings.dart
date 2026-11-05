import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('fr'), Locale('en'), Locale('ar')];

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  String get(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  static const _values = <String, Map<String, String>>{
    'en': {
      'appName': 'TaskFlow',
      'dashboard': 'Dashboard',
      'tasks': 'Tasks',
      'settings': 'Settings',
      'myTasks': 'My tasks',
      'total': 'Total',
      'completed': 'Completed',
      'overdue': 'Overdue',
      'upcoming': 'Upcoming',
      'progress': 'Your progress',
      'overview': 'Task overview',
      'noTasks': 'No tasks yet. Add one to get started.',
      'todo': 'To do',
      'inProgress': 'In progress',
      'done': 'Done',
      'newTask': 'New task',
      'editTask': 'Edit task',
      'taskDetails': 'Task details',
      'description': 'Description',
      'dueDate': 'Due date',
      'priority': 'Priority',
      'status': 'Status',
      'low': 'Low',
      'normal': 'Normal',
      'high': 'High',
      'notSet': 'Not set',
      'appearance': 'Appearance',
      'language': 'Language',
      'notifications': 'Notifications',
      'notificationsHint': 'Receive task reminders and updates',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'english': 'English',
      'french': 'French',
      'arabic': 'Arabic',
      'account': 'Account',
      'signOut': 'Sign out',
      'delete': 'Delete',
      'edit': 'Edit',
      'retry': 'Retry',
      'close': 'Close',
    },
    'fr': {
      'appName': 'TaskFlow',
      'dashboard': 'Tableau de bord',
      'tasks': 'Tâches',
      'settings': 'Paramètres',
      'myTasks': 'Mes tâches',
      'total': 'Total',
      'completed': 'Terminées',
      'overdue': 'En retard',
      'upcoming': 'À venir',
      'progress': 'Votre progression',
      'overview': 'Aperçu des tâches',
      'noTasks': 'Aucune tâche. Ajoutez-en une pour commencer.',
      'todo': 'À faire',
      'inProgress': 'En cours',
      'done': 'Terminées',
      'newTask': 'Nouvelle tâche',
      'editTask': 'Modifier la tâche',
      'taskDetails': 'Détails de la tâche',
      'description': 'Description',
      'dueDate': "Date d'échéance",
      'priority': 'Priorité',
      'status': 'Statut',
      'low': 'Faible',
      'normal': 'Normale',
      'high': 'Élevée',
      'notSet': 'Non définie',
      'appearance': 'Apparence',
      'language': 'Langue',
      'notifications': 'Notifications',
      'notificationsHint': 'Recevoir les rappels et les mises à jour',
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'english': 'Anglais',
      'french': 'Français',
      'arabic': 'Arabe',
      'account': 'Compte',
      'signOut': 'Déconnexion',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'retry': 'Réessayer',
      'close': 'Fermer',
    },
    'ar': {
      'appName': 'تاسك فلو',
      'dashboard': 'لوحة التحكم',
      'tasks': 'المهام',
      'settings': 'الإعدادات',
      'myTasks': 'مهامي',
      'total': 'المجموع',
      'completed': 'مكتملة',
      'overdue': 'متأخرة',
      'upcoming': 'قادمة',
      'progress': 'تقدمك',
      'overview': 'نظرة عامة على المهام',
      'noTasks': 'لا توجد مهام. أضف مهمة للبدء.',
      'todo': 'للإنجاز',
      'inProgress': 'قيد التنفيذ',
      'done': 'مكتملة',
      'newTask': 'مهمة جديدة',
      'editTask': 'تعديل المهمة',
      'taskDetails': 'تفاصيل المهمة',
      'description': 'الوصف',
      'dueDate': 'تاريخ الاستحقاق',
      'priority': 'الأولوية',
      'status': 'الحالة',
      'low': 'منخفضة',
      'normal': 'عادية',
      'high': 'مرتفعة',
      'notSet': 'غير محدد',
      'appearance': 'المظهر',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'notificationsHint': 'استلام تذكيرات وتحديثات المهام',
      'light': 'فاتح',
      'dark': 'داكن',
      'system': 'النظام',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'arabic': 'العربية',
      'account': 'الحساب',
      'signOut': 'تسجيل الخروج',
      'delete': 'حذف',
      'edit': 'تعديل',
      'retry': 'إعادة المحاولة',
      'close': 'إغلاق',
    },
  };
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(AppStringsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  String tr(String key) => AppStrings.of(this).get(key);
}
