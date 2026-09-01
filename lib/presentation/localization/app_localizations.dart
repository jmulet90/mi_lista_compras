import 'package:flutter/material.dart';

import '../app_settings.dart';

class AppLanguage {
  final String code;
  final String nativeName;
  final String flag;

  const AppLanguage(this.code, this.nativeName, this.flag);
}

class AppLocalizations {
  final String langCode;

  AppLocalizations(this.langCode);

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage('es', 'Español', '🇪🇸'),
    AppLanguage('en', 'English', '🇬🇧'),
    AppLanguage('pt', 'Português', '🇧🇷'),
    AppLanguage('fr', 'Français', '🇫🇷'),
    AppLanguage('de', 'Deutsch', '🇩🇪'),
    AppLanguage('it', 'Italiano', '🇮🇹'),
    AppLanguage('zh', '中文', '🇨🇳'),
    AppLanguage('hi', 'हिन्दी', '🇮🇳'),
    AppLanguage('ar', 'العربية', '🇸🇦'),
    AppLanguage('ru', 'Русский', '🇷🇺'),
  ];

  static AppLocalizations of(BuildContext context) {
    final settings = AppSettings.of(context);
    return AppLocalizations(settings.language);
  }

  AppLanguage get currentLanguage => supportedLanguages.firstWhere(
        (l) => l.code == langCode,
        orElse: () => supportedLanguages.first,
      );

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('pt'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('zh'),
    Locale('hi'),
    Locale('ar'),
    Locale('ru'),
  ];

  static bool isSupported(String code) =>
      supportedLanguages.any((l) => l.code == code);

  static String _normalize(String input) {
    var lower = input.trim().toLowerCase();
    const replacements = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    replacements.forEach((k, v) => lower = lower.replaceAll(k, v));
    return lower;
  }

  String _s(String key) =>
      _strings[key]?[langCode] ?? _strings[key]!['es']!;

  String interpolate(String key, Map<String, String> values) {
    var text = _s(key);
    values.forEach((placeholder, replacement) {
      text = text.replaceFirst('{$placeholder}', replacement);
    });
    return text;
  }

  static const Map<String, Map<String, String>> _strings = {
    'appName': {
      'es': 'Buy&Stock', 'en': 'Buy&Stock', 'pt': 'Buy&Stock',
      'fr': 'Buy&Stock', 'de': 'Buy&Stock', 'it': 'Buy&Stock',
      'zh': 'Buy&Stock', 'hi': 'Buy&Stock', 'ar': 'Buy&Stock', 'ru': 'Buy&Stock',
    },
    'buyTitle': {
      'es': 'Comprar - Lista de Compras', 'en': 'Buy - Shopping List', 'pt': 'Comprar - Lista de Compras',
      'fr': 'Achats - Liste de courses', 'de': 'Einkaufen - Einkaufsliste', 'it': 'Acquisti - Lista della spesa',
      'zh': '购买 - 购物清单', 'hi': 'खरीदें - खरीदारी सूची', 'ar': 'شراء - قائمة التسوق', 'ru': 'Покупки - Список покупок',
    },
    'stockTitle': {
      'es': 'Despensa - Inventario', 'en': 'Stock - Inventory', 'pt': 'Despensa - Inventário',
      'fr': 'Garde-manger - Inventaire', 'de': 'Vorrat - Inventar', 'it': 'Dispensa - Inventario',
      'zh': '储藏室 - 库存', 'hi': 'पैंट्री - सूची', 'ar': 'المؤن - المخزون', 'ru': 'Кладовая - Запасы',
    },
    'navBuy': {
      'es': 'Comprar', 'en': 'Buy', 'pt': 'Comprar', 'fr': 'Acheter', 'de': 'Einkaufen',
      'it': 'Compra', 'zh': '购买', 'hi': 'खरीदें', 'ar': 'شراء', 'ru': 'Покупки',
    },
    'navStock': {
      'es': 'Despensa', 'en': 'Stock', 'pt': 'Despensa', 'fr': 'Réserve', 'de': 'Vorrat',
      'it': 'Dispensa', 'zh': '储藏室', 'hi': 'पैंट्री', 'ar': 'المؤن', 'ru': 'Запасы',
    },
    'settings': {
      'es': 'Ajustes', 'en': 'Settings', 'pt': 'Configurações', 'fr': 'Paramètres',
      'de': 'Einstellungen', 'it': 'Impostazioni', 'zh': '设置', 'hi': 'सेटिंग्स',
      'ar': 'الإعدادات', 'ru': 'Настройки',
    },
    'darkMode': {
      'es': 'Modo Oscuro', 'en': 'Dark Mode', 'pt': 'Modo Escuro', 'fr': 'Mode sombre',
      'de': 'Dunkelmodus', 'it': 'Modalità scura', 'zh': '深色模式', 'hi': 'डार्क मोड',
      'ar': 'الوضع الداكن', 'ru': 'Тёмная тема',
    },
    'categoryView': {
      'es': 'Vista de categorías', 'en': 'Category View', 'pt': 'Vista de categorias',
      'fr': 'Vue des catégories', 'de': 'Kategorieansicht', 'it': 'Vista categorie',
      'zh': '分类视图', 'hi': 'श्रेणी दृश्य', 'ar': 'عرض الفئات', 'ru': 'Вид категорий',
    },
    'categoryLabel': {
      'es': 'Categoría', 'en': 'Category', 'pt': 'Categoria', 'fr': 'Catégorie',
      'de': 'Kategorie', 'it': 'Categoria', 'zh': '分类', 'hi': 'श्रेणी',
      'ar': 'الفئة', 'ru': 'Категория',
    },
    'list': {
      'es': 'Lista', 'en': 'List', 'pt': 'Lista', 'fr': 'Liste', 'de': 'Liste',
      'it': 'Lista', 'zh': '列表', 'hi': 'सूची', 'ar': 'قائمة', 'ru': 'Список',
    },
    'gallery': {
      'es': 'Galería', 'en': 'Gallery', 'pt': 'Galeria', 'fr': 'Galerie', 'de': 'Galerie',
      'it': 'Galleria', 'zh': '画廊', 'hi': 'गैलरी', 'ar': 'المعرض', 'ru': 'Галерея',
    },
    'language': {
      'es': 'Idioma', 'en': 'Language', 'pt': 'Idioma', 'fr': 'Langue', 'de': 'Sprache',
      'it': 'Lingua', 'zh': '语言', 'hi': 'भाषा', 'ar': 'اللغة', 'ru': 'Язык',
    },
    'addCategory': {
      'es': 'Nueva Categoría', 'en': 'New Category', 'pt': 'Nova Categoria',
      'fr': 'Nouvelle catégorie', 'de': 'Neue Kategorie', 'it': 'Nuova categoria',
      'zh': '新建分类', 'hi': 'नई श्रेणी', 'ar': 'فئة جديدة', 'ru': 'Новая категория',
    },
    'categoryAlreadyExists': {
      'es': 'Ya existe una categoría con ese nombre', 'en': 'A category with that name already exists',
      'pt': 'Já existe uma categoria com esse nome', 'fr': 'Une catégorie avec ce nom existe déjà',
      'de': 'Eine Kategorie mit diesem Namen existiert bereits', 'it': 'Esiste già una categoria con questo nome',
      'zh': '已存在同名分类', 'hi': 'इस नाम की श्रेणी पहले से मौजूद है',
      'ar': 'توجد فئة بهذا الاسم بالفعل', 'ru': 'Категория с таким названием уже существует',
    },
    'newProduct': {
      'es': 'Nuevo Producto', 'en': 'New Product', 'pt': 'Novo Produto',
      'fr': 'Nouveau produit', 'de': 'Neues Produkt', 'it': 'Nuovo prodotto',
      'zh': '新建商品', 'hi': 'नया उत्पाद', 'ar': 'منتج جديد', 'ru': 'Новый товар',
    },
    'editCategory': {
      'es': 'Editar Categoría', 'en': 'Edit Category', 'pt': 'Editar Categoria',
      'fr': 'Modifier la catégorie', 'de': 'Kategorie bearbeiten', 'it': 'Modifica categoria',
      'zh': '编辑分类', 'hi': 'श्रेणी संपादित करें', 'ar': 'تعديل الفئة', 'ru': 'Изменить категорию',
    },
    'deleteCategory': {
      'es': 'Eliminar categoría', 'en': 'Delete Category', 'pt': 'Eliminar categoria',
      'fr': 'Supprimer la catégorie', 'de': 'Kategorie löschen', 'it': 'Elimina categoria',
      'zh': '删除分类', 'hi': 'श्रेणी हटाएं', 'ar': 'حذف الفئة', 'ru': 'Удалить категорию',
    },
    'cancel': {
      'es': 'Cancelar', 'en': 'Cancel', 'pt': 'Cancelar', 'fr': 'Annuler', 'de': 'Abbrechen',
      'it': 'Annulla', 'zh': '取消', 'hi': 'रद्द करें', 'ar': 'إلغاء', 'ru': 'Отмена',
    },
    'save': {
      'es': 'Guardar', 'en': 'Save', 'pt': 'Salvar', 'fr': 'Enregistrer', 'de': 'Speichern',
      'it': 'Salva', 'zh': '保存', 'hi': 'सहेजें', 'ar': 'حفظ', 'ru': 'Сохранить',
    },
    'add': {
      'es': 'Añadir', 'en': 'Add', 'pt': 'Adicionar', 'fr': 'Ajouter', 'de': 'Hinzufügen',
      'it': 'Aggiungi', 'zh': '添加', 'hi': 'जोड़ें', 'ar': 'إضافة', 'ru': 'Добавить',
    },
    'delete': {
      'es': 'Eliminar', 'en': 'Delete', 'pt': 'Eliminar', 'fr': 'Supprimer', 'de': 'Löschen',
      'it': 'Elimina', 'zh': '删除', 'hi': 'हटाएं', 'ar': 'حذف', 'ru': 'Удалить',
    },
    'edit': {
      'es': 'Editar', 'en': 'Edit', 'pt': 'Editar', 'fr': 'Modifier', 'de': 'Bearbeiten',
      'it': 'Modifica', 'zh': '编辑', 'hi': 'संपादित करें', 'ar': 'تعديل', 'ru': 'Изменить',
    },
    'productsCount': {
      'es': 'productos', 'en': 'products', 'pt': 'produtos', 'fr': 'produits',
      'de': 'Produkte', 'it': 'prodotti', 'zh': '件商品', 'hi': 'उत्पाद',
      'ar': 'منتجات', 'ru': 'товаров',
    },
    'noCategories': {
      'es': 'No hay categorías creadas.', 'en': 'No categories created.',
      'pt': 'Não há categorias criadas.', 'fr': 'Aucune catégorie créée.',
      'de': 'Keine Kategorien erstellt.', 'it': 'Nessuna categoria creata.',
      'zh': '还没有创建分类。', 'hi': 'कोई श्रेणी नहीं बनी है।',
      'ar': 'لا توجد فئات بعد.', 'ru': 'Категории ещё не созданы.',
    },
    'emptyCategoriesSubtitle': {
      'es': 'Crea tu primera categoría para empezar a organizar tus listas.',
      'en': 'Create your first category to start organizing your lists.',
      'pt': 'Crie sua primeira categoria para começar a organizar suas listas.',
      'fr': 'Créez votre première catégorie pour organiser vos listes.',
      'de': 'Erstelle deine erste Kategorie, um deine Listen zu organisieren.',
      'it': 'Crea la prima categoria per iniziare a organizzare i tuoi elenchi.',
      'zh': '创建你的第一个分类，开始整理清单。',
      'hi': 'सूचियाँ व्यवस्थित करने के लिए अपनी पहली श्रेणी बनाएं।',
      'ar': 'أنشئ فئتك الأولى لتنظيم قوائمك.',
      'ru': 'Создайте первую категорию, чтобы организовать свои списки.',
    },
    'noProducts': {
      'es': 'Sin productos en esta categoría', 'en': 'No products in this category',
      'pt': 'Sem produtos nesta categoria', 'fr': 'Aucun produit dans cette catégorie',
      'de': 'Keine Produkte in dieser Kategorie', 'it': 'Nessun prodotto in questa categoria',
      'zh': '此分类中暂无商品', 'hi': 'इस श्रेणी में कोई उत्पाद नहीं',
      'ar': 'لا توجد منتجات في هذه الفئة', 'ru': 'В этой категории нет товаров',
    },
    'emptyProductsSubtitle': {
      'es': 'Añade productos con el botón +.',
      'en': 'Add products with the + button.',
      'pt': 'Adicione produtos com o botão +.',
      'fr': 'Ajoutez des produits avec le bouton +.',
      'de': 'Füge Produkte mit der +-Schaltfläche hinzu.',
      'it': 'Aggiungi prodotti con il pulsante +.',
      'zh': '使用 + 按钮添加商品。',
      'hi': '+ बटन से उत्पाद जोड़ें।',
      'ar': 'أضف المنتجات باستخدام زر +.',
      'ru': 'Добавляйте товары кнопкой +.',
    },
    'about': {
      'es': 'Acerca de', 'en': 'About', 'pt': 'Sobre', 'fr': 'À propos', 'de': 'Über',
      'it': 'Info', 'zh': '关于', 'hi': 'ऐप के बारे में', 'ar': 'حول', 'ru': 'О приложении',
    },
    'version': {
      'es': 'Versión 1.0.0', 'en': 'Version 1.0.0', 'pt': 'Versão 1.0.0',
      'fr': 'Version 1.0.0', 'de': 'Version 1.0.0', 'it': 'Versione 1.0.0',
      'zh': '版本 1.0.0', 'hi': 'संस्करण 1.0.0', 'ar': 'الإصدار 1.0.0', 'ru': 'Версия 1.0.0',
    },
    'nameLabel': {
      'es': 'Nombre', 'en': 'Name', 'pt': 'Nome', 'fr': 'Nom', 'de': 'Name',
      'it': 'Nome', 'zh': '名称', 'hi': 'नाम', 'ar': 'الاسم', 'ru': 'Название',
    },
    'exampleProductHint': {
      'es': 'Ej. Queso', 'en': 'e.g. Cheese', 'pt': 'ex.: Queijo', 'fr': 'ex. : Fromage',
      'de': 'z. B. Käse', 'it': 'es. Formaggio', 'zh': '例如：奶酪', 'hi': 'जैसे चीज़',
      'ar': 'مثال: جبن', 'ru': 'напр. Сыр',
    },
    'exampleCategoryHint': {
      'es': 'Ej. Mascotas', 'en': 'e.g. Pets', 'pt': 'ex.: Animais', 'fr': 'ex. : Animaux',
      'de': 'z. B. Haustiere', 'it': 'es. Animali', 'zh': '例如：宠物', 'hi': 'जैसे पालतू जानवर',
      'ar': 'مثال: حيوانات أليفة', 'ru': 'напр. Питомцы',
    },
    'visualCustomization': {
      'es': 'Personalización visual:', 'en': 'Visual customization:',
      'pt': 'Personalização visual:', 'fr': 'Personnalisation visuelle :',
      'de': 'Visuelle Anpassung:', 'it': 'Personalizzazione visiva:',
      'zh': '自定义外观：', 'hi': 'विज़ुअल अनुकूलन:', 'ar': 'التخصيص المرئي:',
      'ru': 'Визуальное оформление:',
    },
    'camera': {
      'es': 'Cámara', 'en': 'Camera', 'pt': 'Câmera', 'fr': 'Appareil photo',
      'de': 'Kamera', 'it': 'Fotocamera', 'zh': '相机', 'hi': 'कैमरा',
      'ar': 'الكاميرا', 'ru': 'Камера',
    },
    'galleryPicker': {
      'es': 'Galería', 'en': 'Gallery', 'pt': 'Galeria', 'fr': 'Galerie',
      'de': 'Galerie', 'it': 'Galleria', 'zh': '相册', 'hi': 'गैलरी',
      'ar': 'معرض الصور', 'ru': 'Галерея',
    },
    'deleteProductConfirm': {
      'es': '¿Deseas eliminar el producto "{name}"?',
      'en': 'Do you want to delete the product "{name}"?',
      'pt': 'Deseja excluir o produto "{name}"?',
      'fr': 'Voulez-vous supprimer le produit « {name} » ?',
      'de': 'Möchten Sie das Produkt „{name}" löschen?',
      'it': 'Vuoi eliminare il prodotto "{name}"?',
      'zh': '要删除商品“{name}”吗？',
      'hi': 'क्या आप उत्पाद "{name}" हटाना चाहते हैं?',
      'ar': 'هل تريد حذف المنتج "{name}"؟',
      'ru': 'Удалить товар «{name}»?',
    },
    'deleteCategoryConfirm': {
      'es': '¿Deseas eliminar la categoría "{name}"?',
      'en': 'Do you want to delete the category "{name}"?',
      'pt': 'Deseja excluir a categoria "{name}"?',
      'fr': 'Voulez-vous supprimer la catégorie « {name} » ?',
      'de': 'Möchten Sie die Kategorie „{name}" löschen?',
      'it': 'Vuoi eliminare la categoria "{name}"?',
      'zh': '要删除分类“{name}”吗？',
      'hi': 'क्या आप श्रेणी "{name}" हटाना चाहते हैं?',
      'ar': 'هل تريد حذف الفئة "{name}"؟',
      'ru': 'Удалить категорию «{name}»?',
    },
    'shareList': {
      'es': 'Compartir Lista', 'en': 'Share List', 'pt': 'Partilhar Lista',
      'fr': 'Partager la liste', 'de': 'Liste teilen', 'it': 'Condividi lista',
      'zh': '分享列表', 'hi': 'सूची साझा करें', 'ar': 'مشاركة القائمة', 'ru': 'Поделиться списком',
    },
    'exportList': {
      'es': 'Exportar', 'en': 'Export', 'pt': 'Exportar',
      'fr': 'Exporter', 'de': 'Exportieren', 'it': 'Esporta',
      'zh': '导出', 'hi': 'निर्यात', 'ar': 'تصدير', 'ru': 'Экспорт',
    },
    'exportListTitle': {
      'es': 'Exportar lista de Comprar', 'en': 'Export shopping list',
      'pt': 'Exportar lista de compras', 'fr': 'Exporter la liste de courses',
      'de': 'Einkaufsliste exportieren', 'it': 'Esporta lista della spesa',
      'zh': '导出购物清单', 'hi': 'खरीदारी सूची निर्यात करें',
      'ar': 'تصدير قائمة التسوق', 'ru': 'Экспорт списка покупок',
    },
    'exportAsPdf': {
      'es': 'PDF', 'en': 'PDF', 'pt': 'PDF',
      'fr': 'PDF', 'de': 'PDF', 'it': 'PDF',
      'zh': 'PDF', 'hi': 'PDF', 'ar': 'PDF', 'ru': 'PDF',
    },
'exportAsImage': {
      'es': 'Imagen', 'en': 'Image', 'pt': 'Imagem',
      'fr': 'Image', 'de': 'Bild', 'it': 'Immagine',
      'zh': '图片', 'hi': 'छवि', 'ar': 'Picture', 'ru': 'Изображение',
    },
    'all': {
      'es': 'Todas', 'en': 'All', 'pt': 'Todas', 'fr': 'Toutes', 'de': 'Alle',
      'it': 'Tutte', 'zh': '全部', 'hi': 'सभी', 'ar': 'جميع', 'ru': 'Все',
    },
    'exportListEmpty': {
      'es': 'Tu lista de Comprar está vacía', 'en': 'Your shopping list is empty',
      'pt': 'A sua lista de compras está vazia', 'fr': 'Votre liste de courses est vide',
      'de': 'Deine Einkaufsliste ist leer', 'it': 'La lista della spesa è vuota',
      'zh': '您的购物清单为空', 'hi': 'आपकी खरीदारी सूची खाली है',
      'ar': 'قائمة التسوق الخاصة بك فارغة', 'ru': 'Ваш список покупок пуст',
    },
    'exporting': {
      'es': 'Generando archivo…', 'en': 'Generating file…', 'pt': 'A gerar ficheiro…',
      'fr': 'Génération du fichier…', 'de': 'Datei wird erstellt…',
      'it': 'Generazione del file…', 'zh': '正在生成文件…',
      'hi': 'फ़ाइल बनाई जा रही है…', 'ar': 'جارٍ إنشاء الملف…',
      'ru': 'Создание файла…',
    },
    'exportFailed': {
      'es': 'No se pudo generar el archivo', 'en': 'Could not generate the file',
      'pt': 'Não foi possível gerar o ficheiro', 'fr': 'Impossible de générer le fichier',
      'de': 'Datei konnte nicht erstellt werden', 'it': 'Impossibile generare il file',
      'zh': '无法生成文件', 'hi': 'फ़ाइल नहीं बनाई जा सकी',
      'ar': 'تعذّر إنشاء الملف', 'ru': 'Не удалось создать файл',
    },
    'shoppingList': {
      'es': 'Lista de Compras', 'en': 'Shopping List', 'pt': 'Lista de Compras',
      'fr': 'Liste de courses', 'de': 'Einkaufsliste', 'it': 'Lista della spesa',
      'zh': '购物清单', 'hi': 'खरीदारी सूची', 'ar': 'قائمة التسوق', 'ru': 'Список покупок',
    },
    'subcategory': {
      'es': 'Subcategoría', 'en': 'Subcategory', 'pt': 'Subcategoria',
      'fr': 'Sous-catégorie', 'de': 'Unterkategorie', 'it': 'Sottocategoria',
      'zh': '子类别', 'hi': 'उपश्रेणी', 'ar': 'فئة فرعية', 'ru': 'Подкатегория',
    },
    'subcategories': {
      'es': 'Subcategorías', 'en': 'Subcategories', 'pt': 'Subcategorias',
      'fr': 'Sous-catégories', 'de': 'Unterkategorien', 'it': 'Sottocategorie',
      'zh': '子类别', 'hi': 'उपश्रेणियाँ', 'ar': 'فئات فرعية', 'ru': 'Подкатегории',
    },
    'noSubcategory': {
      'es': 'Sin subcategoría', 'en': 'No subcategory', 'pt': 'Sem subcategoria',
      'fr': 'Sans sous-catégorie', 'de': 'Ohne Unterkategorie', 'it': 'Senza sottocategoria',
      'zh': '无子类别', 'hi': 'कोई उपश्रेणी नहीं', 'ar': 'بدون فئة فرعية', 'ru': 'Без подкатегории',
    },
    'newSubcategory': {
      'es': 'Nueva subcategoría', 'en': 'New subcategory', 'pt': 'Nova subcategoria',
      'fr': 'Nouvelle sous-catégorie', 'de': 'Neue Unterkategorie', 'it': 'Nuova sottocategoria',
      'zh': '新建子类别', 'hi': 'नई उपश्रेणी', 'ar': 'فئة فرعية جديدة', 'ru': 'Новая подкатегория',
    },
    'subcategoryHint': {
      'es': 'Ej: Lácteos, Limpieza…', 'en': 'E.g. Dairy, Cleaning…',
      'pt': 'Ex.: Laticínios, Limpeza…', 'fr': 'Ex. : Laitage, Nettoyage…',
      'de': 'Z. B. Milchprodukte, Reinigung…', 'it': 'Es.: Latticini, Pulizia…',
      'zh': '例如：乳制品、清洁…', 'hi': 'जैसे: डेयरी, सफ़ाई…',
      'ar': 'مثال: ألبان، تنظيف…', 'ru': 'Напр.: Молочные, Уборка…',
    },
    'renameSubcategory': {
      'es': 'Renombrar subcategoría', 'en': 'Rename subcategory', 'pt': 'Renomear subcategoria',
      'fr': 'Renommer la sous-catégorie', 'de': 'Unterkategorie umbenennen',
      'it': 'Rinomina sottocategoria', 'zh': '重命名子类别', 'hi': 'उपश्रेणी का नाम बदलें',
      'ar': 'إعادة تسمية الفئة الفرعية', 'ru': 'Переименовать подкатегорию',
    },
    'deleteSubcategory': {
      'es': 'Eliminar subcategoría', 'en': 'Delete subcategory', 'pt': 'Eliminar subcategoria',
      'fr': 'Supprimer la sous-catégorie', 'de': 'Unterkategorie löschen',
      'it': 'Elimina sottocategoria', 'zh': '删除子类别', 'hi': 'उपश्रेणी हटाएं',
      'ar': 'حذف الفئة الفرعية', 'ru': 'Удалить подкатегорию',
    },
    'deleteSubcategoryConfirm': {
      'es': 'Se quitará “{name}” de sus productos.', 'en': 'It will be removed from “{name}” products.',
      'pt': 'Será removida dos produtos de “{name}”.', 'fr': 'Elle sera retirée des produits « {name} ».',
      'de': 'Sie wird von den Produkten „{name}“ entfernt.', 'it': 'Sarà rimossa dai prodotti di “{name}”.',
      'zh': '它将从“{name}”的产品中移除。', 'hi': 'इसे “{name}” के उत्पादों से हटा दिया जाएगा।',
      'ar': 'سيتم إزالتها من منتجات «{name}».', 'ru': 'Она будет убрана из товаров «{name}».',
    },
    'subcategoryCreated': {
      'es': 'Subcategoría “{name}” creada. Aparecerá cuando tenga productos.',
      'en': 'Subcategory “{name}” created. It will appear once it has products.',
      'pt': 'Subcategoria “{name}” criada. Aparecerá quando tiver produtos.',
      'fr': 'Sous-catégorie « {name} » créée. Elle apparaîtra dès qu’elle aura des produits.',
      'de': 'Unterkategorie „{name}“ erstellt. Sie erscheint, sobald sie Produkte hat.',
      'it': 'Sottocategoria “{name}” creata. Apparirà quando avrà prodotti.',
      'zh': '子类别“{name}”已创建。当它有产品时才会显示。',
      'hi': 'उपश्रेणी “{name}” बनाई गई। जब इसमें उत्पाद होंगे तभी दिखेगी।',
      'ar': 'تم إنشاء الفئة الفرعية «{name}». ستظهر عندما تحتوي على منتجات.',
      'ru': 'Подкатегория «{name}» создана. Она появится, когда в ней будут товары.',
    },
    'moveProduct': {
      'es': 'Mover producto', 'en': 'Move product', 'pt': 'Mover produto',
      'fr': 'Déplacer le produit', 'de': 'Produkt verschieben', 'it': 'Sposta prodotto',
      'zh': '移动产品', 'hi': 'उत्पाद स्थानांतरित करें', 'ar': 'نقل المنتج',
      'ru': 'Переместить товар',
    },
    'movedProductTo': {
      'es': 'Producto movido a {sub}', 'en': 'Product moved to {sub}',
      'pt': 'Produto movido para {sub}', 'fr': 'Produit déplacé vers {sub}',
      'de': 'Produkt verschoben zu {sub}', 'it': 'Prodotto spostato in {sub}',
      'zh': '产品已移动到{sub}', 'hi': 'उत्पाद को {sub} में स्थानांतरित किया गया',
      'ar': 'تم نقل المنتج إلى {sub}', 'ru': 'Товар перемещён в {sub}',
    },
    'moveToCategory': {
      'es': 'Mover a otra categoría', 'en': 'Move to another category',
      'pt': 'Mover para outra categoria', 'fr': 'Déplacer vers une autre catégorie',
      'de': 'In eine andere Kategorie verschieben', 'it': 'Sposta in un\'altra categoria',
      'zh': '移动到其他分类', 'hi': 'दूसरी श्रेणी में ले जाएँ',
      'ar': 'نقل إلى فئة أخرى', 'ru': 'Переместить в другую категорию',
    },
    'select': {
      'es': 'Seleccionar', 'en': 'Select', 'pt': 'Selecionar',
      'fr': 'Sélectionner', 'de': 'Auswählen', 'it': 'Seleziona',
      'zh': '选择', 'hi': 'चुनें', 'ar': 'تحديد', 'ru': 'Выбрать',
    },
    'move': {
      'es': 'Mover', 'en': 'Move', 'pt': 'Mover',
      'fr': 'Déplacer', 'de': 'Verschieben', 'it': 'Sposta',
      'zh': '移动', 'hi': 'स्थानांतरित करें', 'ar': 'نقل', 'ru': 'Переместить',
    },
    'selectedCount': {
      'es': '{count} seleccionados', 'en': '{count} selected',
      'pt': '{count} selecionados', 'fr': '{count} sélectionnés',
      'de': '{count} ausgewählt', 'it': '{count} selezionati',
      'zh': '已选择 {count} 项', 'hi': '{count} चुने गए',
      'ar': 'تم تحديد {count}', 'ru': 'Выбрано: {count}',
    },
    'movedProductsTo': {
      'es': '{count} productos movidos a {sub}', 'en': '{count} products moved to {sub}',
      'pt': '{count} produtos movidos para {sub}', 'fr': '{count} produits déplacés vers {sub}',
      'de': '{count} Produkte verschoben zu {sub}', 'it': '{count} prodotti spostati in {sub}',
      'zh': '{count} 个产品已移动到{sub}', 'hi': '{count} उत्पाद {sub} में स्थानांतरित किए गए',
      'ar': 'تم نقل {count} منتج إلى {sub}', 'ru': '{count} товаров перемещено в {sub}',
    },
    'shareListSub': {
      'es': 'Añadir usuario secundario', 'en': 'Add secondary user',
      'pt': 'Adicionar utilizador secundário', 'fr': 'Ajouter un utilisateur secondaire',
      'de': 'Sekundären Benutzer hinzufügen', 'it': 'Aggiungi utente secondario',
      'zh': '添加副用户', 'hi': 'द्वितीय उपयोगकर्ता जोड़ें',
      'ar': 'إضافة مستخدم ثانوي', 'ru': 'Добавить второго пользователя',
    },
    'managePermissions': {
      'es': 'Gestionar Permisos', 'en': 'Manage Permissions', 'pt': 'Gerir Permissões',
      'fr': 'Gérer les autorisations', 'de': 'Berechtigungen verwalten',
      'it': 'Gestisci permessi', 'zh': '管理权限', 'hi': 'अनुमतियाँ प्रबंधित करें',
      'ar': 'إدارة الأذونات', 'ru': 'Управление разрешениями',
    },
    'managePermissionsSub': {
      'es': 'Modificar roles de colaboradores', 'en': 'Modify collaborator roles',
      'pt': 'Modificar funções de colaboradores', 'fr': 'Modifier les rôles des collaborateurs',
      'de': 'Mitarbeiterrollen ändern', 'it': 'Modificare i ruoli dei collaboratori',
      'zh': '修改协作者角色', 'hi': 'सहयोगी भूमिकाएँ बदलें',
      'ar': 'تعديل أدوار المتعاونين', 'ru': 'Изменить роли соавторов',
    },
    'signOut': {
      'es': 'Cerrar sesión', 'en': 'Sign out', 'pt': 'Terminar sessão',
      'fr': 'Se déconnecter', 'de': 'Abmelden', 'it': 'Esci',
      'zh': '退出登录', 'hi': 'साइन आउट', 'ar': 'تسجيل الخروج', 'ru': 'Выйти',
    },
    'manageCollaborators': {
      'es': 'Gestionar Colaboradores', 'en': 'Manage Collaborators',
      'pt': 'Gerir Colaboradores', 'fr': 'Gérer les collaborateurs',
      'de': 'Mitarbeiter verwalten', 'it': 'Gestisci collaboratori',
      'zh': '管理协作者', 'hi': 'सहयोगी प्रबंधित करें',
      'ar': 'إدارة المتعاونين', 'ru': 'Управление соавторами',
    },
    'notAuthenticated': {
      'es': 'Usuario no autenticado', 'en': 'User not authenticated',
      'pt': 'Usuário não autenticado', 'fr': 'Utilisateur non authentifié',
      'de': 'Benutzer nicht angemeldet', 'it': 'Utente non autenticato',
      'zh': '用户未登录', 'hi': 'उपयोगकर्ता प्रमाणित नहीं है',
      'ar': 'المستخدم غير مصادق عليه', 'ru': 'Пользователь не авторизован',
    },
    'noCollaborators': {
      'es': 'No tienes colaboradores añadidos todavía.',
      'en': 'You have no collaborators yet.',
      'pt': 'Você ainda não tem colaboradores.',
      'fr': "Vous n'avez pas encore de collaborateurs.",
      'de': 'Sie haben noch keine Mitarbeiter.',
      'it': 'Non hai ancora collaboratori.',
      'zh': '你还没有协作者。',
      'hi': 'आपके पास अभी कोई सहयोगी नहीं है।',
      'ar': 'ليس لديك متعاونون بعد.',
      'ru': 'У вас пока нет соавторов.',
    },
    'removeCollaboratorConfirm': {
      'es': '¿Quitar a {name} como colaborador? Ya no podrá acceder a tus listas.',
      'en': 'Remove {name} as a collaborator? They will lose access to your lists.',
      'pt': 'Remover {name} como colaborador? Ele perderá o acesso às suas listas.',
      'fr': 'Retirer {name} des collaborateurs ? Il perdra l’accès à vos listes.',
      'de': '{name} als Mitarbeiter entfernen? Der Zugriff auf Ihre Listen wird aufgehoben.',
      'it': 'Rimuovere {name} come collaboratore? Perderà l’accesso ai tuoi elenchi.',
      'zh': '移除协作者 {name}？对方将无法再访问你的清单。',
      'hi': '{name} को सहयोगी के रूप में हटाएँ? वे आपकी सूचियों तक पहुँच खो देंगे।',
      'ar': 'إزالة {name} كمتعاون؟ سيفقد الوصول إلى قوائمك.',
      'ru': 'Удалить {name} из соавторов? Он потеряет доступ к вашим спискам.',
    },
    'collaboratorRemoved': {
      'es': 'Colaborador eliminado',
      'en': 'Collaborator removed',
      'pt': 'Colaborador removido',
      'fr': 'Collaborateur retiré',
      'de': 'Mitarbeiter entfernt',
      'it': 'Collaboratore rimosso',
      'zh': '协作者已移除',
      'hi': 'सहयोगी हटाया गया',
      'ar': 'تمت إزالة المتعاون',
      'ru': 'Соавтор удалён',
    },
    'permissionPrefix': {
      'es': 'Permiso:', 'en': 'Permission:', 'pt': 'Permissão:', 'fr': 'Autorisation :',
      'de': 'Berechtigung:', 'it': 'Permesso:', 'zh': '权限：', 'hi': 'अनुमति:',
      'ar': 'الإذن:', 'ru': 'Разрешение:',
    },
    'permissionLabel': {
      'es': 'Permiso', 'en': 'Permission', 'pt': 'Permissão', 'fr': 'Permission',
      'de': 'Berechtigung', 'it': 'Permesso', 'zh': '权限', 'hi': 'अनुमति',
      'ar': 'الصلاحية', 'ru': 'Разрешение',
    },
    'roleFull': {
      'es': 'Control Total', 'en': 'Full Control', 'pt': 'Controlo Total',
      'fr': 'Contrôle total', 'de': 'Vollzugriff', 'it': 'Controllo totale',
      'zh': '完全控制', 'hi': 'पूर्ण नियंत्रण', 'ar': 'تحكم كامل', 'ru': 'Полный контроль',
    },
    'roleDynamic': {
      'es': 'Modo Dinámico', 'en': 'Dynamic Mode', 'pt': 'Modo Dinâmico',
      'fr': 'Mode dynamique', 'de': 'Dynamischer Modus', 'it': 'Modalità dinamica',
      'zh': '动态模式', 'hi': 'डायनामिक मोड', 'ar': 'الوضع الديناميكي', 'ru': 'Динамический режим',
    },
    'roleRead': {
      'es': 'Solo Lectura', 'en': 'Read-only', 'pt': 'Somente leitura',
      'fr': 'Lecture seule', 'de': 'Nur lesen', 'it': 'Sola lettura',
      'zh': '只读', 'hi': 'केवल पढ़ें', 'ar': 'قراءة فقط', 'ru': 'Только чтение',
    },
    'roleUnknown': {
      'es': 'Desconocido', 'en': 'Unknown', 'pt': 'Desconhecido', 'fr': 'Inconnu',
      'de': 'Unbekannt', 'it': 'Sconosciuto', 'zh': '未知', 'hi': 'अज्ञात',
      'ar': 'غير معروف', 'ru': 'Неизвестно',
    },
    'addCollaborator': {
      'es': 'Añadir Colaborador', 'en': 'Add Collaborator', 'pt': 'Adicionar Colaborador',
      'fr': 'Ajouter un collaborateur', 'de': 'Mitarbeiter hinzufügen',
      'it': 'Aggiungi collaboratore', 'zh': '添加协作者', 'hi': 'सहयोगी जोड़ें',
      'ar': 'إضافة متعاون', 'ru': 'Добавить соавтора',
    },
    'collaboratorsUsed': {
      'es': 'Colaboradores: {used}/{max}', 'en': 'Collaborators: {used}/{max}',
      'pt': 'Colaboradores: {used}/{max}', 'fr': 'Collaborateurs : {used}/{max}',
      'de': 'Mitarbeiter: {used}/{max}', 'it': 'Collaboratori: {used}/{max}',
      'zh': '协作者：{used}/{max}', 'hi': 'सहयोगी: {used}/{max}',
      'ar': 'المتعاونون: {used}/{max}', 'ru': 'Соавторы: {used}/{max}',
    },
    'collaboratorsPremiumPlusLimit': {
      'es': 'Con Premium tienes 1 colaborador. Premium Plus te permite hasta 4.',
      'en': 'With Premium you have 1 collaborator. Premium Plus allows up to 4.',
      'pt': 'Com o Premium você tem 1 colaborador. O Premium Plus permite até 4.',
      'fr': 'Avec Premium vous avez 1 collaborateur. Premium Plus permet jusqu’à 4.',
      'de': 'Mit Premium hast du 1 Mitarbeiter. Premium Plus erlaubt bis zu 4.',
      'it': 'Con Premium hai 1 collaboratore. Premium Plus consente fino a 4.',
      'zh': '高级版含 1 名协作者，Premium Plus 最多 4 名。',
      'hi': 'प्रीमियम में 1 सहयोगी मिलता है। प्रीमियम प्लस में 4 तक।',
      'ar': 'تتضمن النسخة المميزة متعاونًا واحدًا، وPremium Plus يسمح حتى 4.',
      'ru': 'С Premium у вас 1 соавтор. Premium Plus позволяет до 4.',
    },
    'collaboratorPrompt': {
      'es': 'Introduce el correo del usuario secundario y selecciona su nivel de permiso:',
      'en': "Enter the secondary user's email and select their permission level:",
      'pt': 'Introduza o email do utilizador secundário e selecione o nível de permissão:',
      'fr': "Saisissez l'e-mail de l'utilisateur secondaire et choisissez son niveau d'autorisation :",
      'de': 'Geben Sie die E-Mail des Sekundärbenutzers ein und wählen Sie die Berechtigungsstufe:',
      'it': "Inserisci l'e-mail dell'utente secondario e seleziona il livello di permesso:",
      'zh': '输入副用户的邮箱并选择其权限级别：',
      'hi': 'द्वितीय उपयोगकर्ता का ईमेल दर्ज करें और अनुमति स्तर चुनें:',
      'ar': 'أدخل البريد الإلكتروني للمستخدم الثانوي واختر مستوى الإذن:',
      'ru': 'Введите email второго пользователя и выберите уровень доступа:',
    },
    'emailLabel': {
      'es': 'Correo electrónico', 'en': 'Email address', 'pt': 'Correio eletrónico',
      'fr': 'Adresse e-mail', 'de': 'E-Mail-Adresse', 'it': 'Indirizzo e-mail',
      'zh': '电子邮箱', 'hi': 'ईमेल पता', 'ar': 'البريد الإلكتروني', 'ru': 'Электронная почта',
    },
    'savedSuccessfully': {
      'es': 'guardado con éxito', 'en': 'saved successfully', 'pt': 'salvo com sucesso',
      'fr': 'enregistré avec succès', 'de': 'erfolgreich gespeichert',
      'it': 'salvato con successo', 'zh': '保存成功', 'hi': 'सफलतापूर्वक सहेजा गया',
      'ar': 'تم الحفظ بنجاح', 'ru': 'успешно сохранён',
    },
    'errorSaving': {
      'es': 'Error al guardar:', 'en': 'Error saving:', 'pt': 'Erro ao guardar:',
      'fr': "Erreur lors de l'enregistrement :", 'de': 'Fehler beim Speichern:',
      'it': 'Errore durante il salvataggio:', 'zh': '保存时出错：', 'hi': 'सहेजने में त्रुटि:',
      'ar': 'خطأ في الحفظ:', 'ru': 'Ошибка сохранения:',
    },
    'unexpectedError': {
      'es': 'Ocurrió un error inesperado', 'en': 'An unexpected error occurred',
      'pt': 'Ocorreu um erro inesperado', 'fr': "Une erreur inattendue s'est produite",
      'de': 'Ein unerwarteter Fehler ist aufgetreten',
      'it': 'Si è verificato un errore imprevisto', 'zh': '发生意外错误',
      'hi': 'एक अनपेक्षित त्रुटि हुई', 'ar': 'حدث خطأ غير متوقع',
      'ru': 'Произошла непредвиденная ошибка',
    },
    'authTabLogin': {
      'es': 'Iniciar sesión', 'en': 'Sign in', 'pt': 'Entrar',
      'fr': 'Connexion', 'de': 'Anmelden', 'it': 'Accedi',
      'zh': '登录', 'hi': 'साइन इन', 'ar': 'تسجيل الدخول', 'ru': 'Вход',
    },
    'authTabRegister': {
      'es': 'Crear cuenta', 'en': 'Create account', 'pt': 'Criar conta',
      'fr': 'Inscription', 'de': 'Registrieren', 'it': 'Registrati',
      'zh': '注册', 'hi': 'खाता बनाएं', 'ar': 'إنشاء حساب', 'ru': 'Регистрация',
    },
    'authTagline': {
      'es': 'Tu despensa y tu lista, siempre sincronizadas',
      'en': 'Your pantry and list, always in sync',
      'pt': 'Sua despensa e lista, sempre sincronizadas',
      'fr': 'Votre réserve et votre liste, toujours synchronisées',
      'de': 'Vorrat und Liste, immer synchron',
      'it': 'Dispensa e lista, sempre sincronizzate',
      'zh': '库存与清单，实时同步', 'hi': 'आपकी पैंट्री और सूची, हमेशा सिंक',
      'ar': 'مؤنتك وقائمتك متزامنتان دائماً',
      'ru': 'Запасы и список всегда синхронны',
    },
    'authPasswordLabel': {
      'es': 'Contraseña', 'en': 'Password', 'pt': 'Senha',
      'fr': 'Mot de passe', 'de': 'Passwort', 'it': 'Password',
      'zh': '密码', 'hi': 'पासवर्ड', 'ar': 'كلمة المرور', 'ru': 'Пароль',
    },
    'authPasswordHintRegister': {
      'es': 'Mínimo 6 caracteres', 'en': 'At least 6 characters',
      'pt': 'Mínimo 6 caracteres', 'fr': '6 caractères minimum',
      'de': 'Mindestens 6 Zeichen', 'it': 'Almeno 6 caratteri',
      'zh': '至少 6 个字符', 'hi': 'कम से कम 6 अक्षर',
      'ar': '6 أحرف على الأقل', 'ru': 'Минимум 6 символов',
    },
    'authLoginButton': {
      'es': 'Entrar', 'en': 'Sign in', 'pt': 'Entrar',
      'fr': 'Se connecter', 'de': 'Anmelden', 'it': 'Accedi',
      'zh': '登录', 'hi': 'साइन इन करें', 'ar': 'تسجيل الدخول', 'ru': 'Войти',
    },
    'authRegisterButton': {
      'es': 'Crear cuenta', 'en': 'Create account', 'pt': 'Criar conta',
      'fr': 'Créer un compte', 'de': 'Konto erstellen', 'it': 'Crea account',
      'zh': '创建账户', 'hi': 'खाता बनाएं', 'ar': 'إنشاء حساب',
      'ru': 'Создать аккаунт',
    },
    'authOrContinue': {
      'es': 'o continúa con', 'en': 'or continue with',
      'pt': 'ou continue com', 'fr': 'ou continuer avec',
      'de': 'oder weiter mit', 'it': 'oppure continua con',
      'zh': '或使用以下方式登录', 'hi': 'या इससे जारी रखें',
      'ar': 'أو تابع باستخدام', 'ru': 'или продолжить с',
    },
    'authGoogleButton': {
      'es': 'Continuar con Google', 'en': 'Continue with Google',
      'pt': 'Continuar com Google', 'fr': 'Continuer avec Google',
      'de': 'Mit Google fortfahren', 'it': 'Continua con Google',
      'zh': '使用 Google 继续', 'hi': 'Google के साथ जारी रखें',
      'ar': 'المتابعة باستخدام Google', 'ru': 'Продолжить с Google',
    },
    'authRequiredField': {
      'es': 'Este campo es obligatorio', 'en': 'This field is required',
      'pt': 'Este campo é obrigatório', 'fr': 'Ce champ est obligatoire',
      'de': 'Dieses Feld ist erforderlich',
      'it': 'Questo campo è obbligatorio',
      'zh': '此字段为必填项', 'hi': 'यह फ़ील्ड आवश्यक है',
      'ar': 'هذا الحقل مطلوب', 'ru': 'Это поле обязательно',
    },
    'errorInvalidEmail': {
      'es': 'El correo no tiene un formato válido',
      'en': 'The email format is invalid',
      'pt': 'O formato do e-mail é inválido',
      "fr": "Le format de l'e-mail est invalide",
      'de': 'Das E-Mail-Format ist ungültig',
      "it": "Il formato dell'e-mail non è valido",
      'zh': '邮箱格式无效', 'hi': 'ईमेल प्रारूप अमान्य है',
      'ar': 'تنسيق البريد الإلكتروني غير صالح',
      'ru': 'Неверный формат почты',
    },
    'errorWrongPassword': {
      'es': 'Contraseña incorrecta', 'en': 'Incorrect password',
      'pt': 'Senha incorreta', 'fr': 'Mot de passe incorrect',
      'de': 'Falsches Passwort', 'it': 'Password errata',
      'zh': '密码错误', 'hi': 'गलत पासवर्ड', 'ar': 'كلمة المرور غير صحيحة',
      'ru': 'Неверный пароль',
    },
    'errorUserNotFound': {
      'es': 'No existe cuenta con ese correo',
      'en': 'No account exists for that email',
      'pt': 'Não há conta para esse e-mail',
      'fr': 'Aucun compte pour cet e-mail',
      'de': 'Kein Konto für diese E-Mail',
      'it': 'Nessun account per questa e-mail',
      'zh': '该邮箱没有账户', 'hi': 'इस ईमेल का कोई खाता नहीं है',
      'ar': 'لا يوجد حساب لهذا البريد',
      'ru': 'Нет аккаунта для этой почты',
    },
    'errorEmailInUse': {
      'es': 'Ya existe una cuenta con ese correo',
      'en': 'An account already exists for that email',
      'pt': 'Já existe conta para esse e-mail',
      'fr': 'Un compte existe déjà pour cet e-mail',
      'de': 'Es gibt bereits ein Konto für diese E-Mail',
      'it': 'Esiste già un account per questa e-mail',
      'zh': '该邮箱已有账户', 'hi': 'इस ईमेल का खाता पहले से है',
      'ar': 'يوجد حساب لهذا البريد بالفعل',
      'ru': 'Аккаунт для этой почты уже есть',
    },
    'errorWeakPassword': {
      'es': 'La contraseña debe tener al menos 6 caracteres',
      'en': 'Password must be at least 6 characters',
      'pt': 'A senha deve ter pelo menos 6 caracteres',
      'fr': 'Le mot de passe doit faire au moins 6 caractères',
      'de': 'Das Passwort muss mindestens 6 Zeichen haben',
      'it': 'La password deve avere almeno 6 caratteri',
      'zh': '密码至少 6 个字符',
      'hi': 'पासवर्ड कम से कम 6 अक्षर का हो',
      'ar': 'كلمة المرور 6 أحرف على الأقل',
      'ru': 'Пароль минимум 6 символов',
    },
    'errorNetwork': {
      'es': 'Sin conexión. Revisa tu red e inténtalo de nuevo',
      'en': 'No connection. Check your network and try again',
      'pt': 'Sem conexão. Verifique sua rede e tente de novo',
      'fr': 'Pas de connexion. Vérifiez le réseau et réessayez',
      'de': 'Keine Verbindung. Netzwerk prüfen und erneut versuchen',
      'it': 'Nessuna connessione. Controlla la rete e riprova',
      'zh': '无网络连接，请检查网络后重试',
      'hi': 'कोई कनेक्शन नहीं। नेटवर्क जाँचें और फिर कोशिश करें',
      'ar': 'لا اتصال. تحقق من الشبكة وحاول مجدداً',
      'ru': 'Нет соединения. Проверьте сеть и повторите',
    },
    'errorGenericAuth': {
      'es': 'Verifica los datos e inténtalo de nuevo',
      'en': 'Check your details and try again',
      'pt': 'Verifique os dados e tente de novo',
      'fr': 'Vérifiez vos informations et réessayez',
      'de': 'Daten prüfen und erneut versuchen',
      'it': 'Controlla i dati e riprova',
      'zh': '请核对信息后重试',
      'hi': 'विवरण जाँचें और फिर कोशिश करें',
      'ar': 'تحقق من البيانات وحاول مجدداً',
      'ru': 'Проверьте данные и повторите',
    },
    'authTermsNote': {
      'es': 'Al continuar aceptas los Términos y la Política de Privacidad',
      'en': 'By continuing you accept the Terms and Privacy Policy',
      'pt': 'Ao continuar você aceita os Termos e a Política de Privacidade',
      'fr':
          "En continuant, vous acceptez les Conditions et la Confidentialité",
      'de':
          'Mit dem Fortfahren akzeptieren Sie die AGB und den Datenschutz',
      'it': "Continuando accetti i Termini e la Privacy",
      'zh': '继续即表示你接受条款和隐私政策',
      'hi': 'जारी रखने पर आप नियम और गोपनीयता नीति स्वीकार करते हैं',
      'ar': 'بالمتابعة أنت توافق على الشروط وسياسة الخصوصية',
      'ru': 'Продолжая, вы принимаете Условия и Конфиденциальность',
    },
    'selectLanguage': {
      'es': 'Selecciona un idioma', 'en': 'Select a language', 'pt': 'Selecione um idioma',
      'fr': 'Choisissez une langue', 'de': 'Sprache auswählen', 'it': 'Seleziona una lingua',
      'zh': '选择语言', 'hi': 'भाषा चुनें', 'ar': 'اختر لغة', 'ru': 'Выберите язык',
    },
    'loading': {
      'es': 'Cargando...', 'en': 'Loading...', 'pt': 'Carregando...', 'fr': 'Chargement...',
      'de': 'Wird geladen...', 'it': 'Caricamento...', 'zh': '加载中...', 'hi': 'लोड हो रहा है...',
      'ar': 'جار التحميل...', 'ru': 'Загрузка...',
    },
    'ownerPrefix': {
      'es': 'Dueño:', 'en': 'Owner:', 'pt': 'Proprietário:', 'fr': 'Propriétaire :',
      'de': 'Besitzer:', 'it': 'Proprietario:', 'zh': '所有者：', 'hi': 'स्वामी:',
      'ar': 'المالك:', 'ru': 'Владелец:',
    },
    'collaboratorOf': {
      'es': 'Colaborador de:', 'en': 'Collaborator of:', 'pt': 'Colaborador de:',
      'fr': 'Collaborateur de :', 'de': 'Mitarbeiter von:', 'it': 'Collaboratore di:',
      'zh': '协作者：', 'hi': 'सहयोगी:', 'ar': 'متعاون مع:', 'ru': 'Соавтор:',
    },
    'emailShort': {
      'es': 'Correo', 'en': 'Email', 'pt': 'E-mail', 'fr': 'E-mail', 'de': 'E-Mail',
      'it': 'E-mail', 'zh': '邮箱', 'hi': 'ईमेल', 'ar': 'البريد الإلكتروني', 'ru': 'Почта',
    },
    'premiumTitle': {
      'es': 'Hazte Premium', 'en': 'Go Premium', 'pt': 'Torne-se Premium',
      'fr': 'Passer à Premium', 'de': 'Premium werden', 'it': 'Diventa Premium',
      'zh': '升级高级版', 'hi': 'प्रीमियम बनें', 'ar': 'النسخة المميزة', 'ru': 'Перейти на Premium',
    },
    'premiumBenefit1': {
      'es': 'Categorías ilimitadas', 'en': 'Unlimited categories', 'pt': 'Categorias ilimitadas',
      'fr': 'Catégories illimitées', 'de': 'Unbegrenzte Kategorien', 'it': 'Categorie illimitate',
      'zh': '无限分类', 'hi': 'असीमित श्रेणियाँ', 'ar': 'فئات غير محدودة', 'ru': 'Неограниченные категории',
    },
    'premiumBenefit2': {
      'es': 'Productos ilimitados por categoría', 'en': 'Unlimited products per category',
      'pt': 'Produtos ilimitados por categoria', 'fr': 'Produits illimités par catégorie',
      'de': 'Unbegrenzte Produkte pro Kategorie', 'it': 'Prodotti illimitati per categoria',
      'zh': '每个分类无限商品', 'hi': 'प्रति श्रेणी असीमित उत्पाद', 'ar': 'منتجات غير محدودة لكل فئة',
      'ru': 'Неограниченные товары в категории',
    },
    'premiumBenefit3': {
      'es': 'Apoya el desarrollo de la app', 'en': 'Support the app development',
      'pt': 'Apoie o desenvolvimento do app', 'fr': 'Soutenez le développement de l’application',
      'de': 'Unterstütze die Entwicklung der App', 'it': 'Sostieni lo sviluppo dell’app',
      'zh': '支持应用开发', 'hi': 'ऐप के विकास का समर्थन करें', 'ar': 'ادعم تطوير التطبيق',
      'ru': 'Поддержите разработку приложения',
    },
    'unlockFor': {
      'es': 'Desbloquear por {price}', 'en': 'Unlock for {price}', 'pt': 'Desbloquear por {price}',
      'fr': 'Débloquer pour {price}', 'de': 'Für {price} freischalten', 'it': 'Sblocca per {price}',
      'zh': '{price} 解锁', 'hi': '{price} में अनलॉक करें', 'ar': 'فتح مقابل {price}',
      'ru': 'Разблокировать за {price}',
    },
    'premiumPriceFallback': {
      'es': '1,99 €', 'en': '€1.99', 'pt': '1,99 €', 'fr': '1,99 €', 'de': '1,99 €',
      'it': '1,99 €', 'zh': '1.99欧元', 'hi': '1.99 यूरो', 'ar': '1.99 يورو', 'ru': '1,99 евро',
    },
    'premiumRestore': {
      'es': 'Restaurar compra', 'en': 'Restore purchase', 'pt': 'Restaurar compra',
      'fr': 'Restaurer l’achat', 'de': 'Kauf wiederherstellen', 'it': 'Ripristina acquisto',
      'zh': '恢复购买', 'hi': 'खरीद पुनर्स्थापित करें', 'ar': 'استعادة الشراء', 'ru': 'Восстановить покупку',
    },
    'premiumActive': {
      'es': 'Ya tienes Premium', 'en': 'You already have Premium', 'pt': 'Você já tem Premium',
      'fr': 'Vous avez déjà Premium', 'de': 'Du hast bereits Premium', 'it': 'Hai già Premium',
      'zh': '你已是高级版', 'hi': 'आपके पास पहले से प्रीमियम है', 'ar': 'لديك النسخة المميزة بالفعل',
      'ru': 'У вас уже есть Premium',
    },
    'premiumLimitCategories': {
      'es': 'Versión gratuita: máximo 8 categorías.',
      'en': 'Free version: up to 8 categories.',
      'pt': 'Versão gratuita: até 8 categorias.',
      'fr': 'Version gratuite : jusqu’à 8 catégories.',
      'de': 'Kostenlose Version: bis zu 8 Kategorien.',
      'it': 'Versione gratuita: fino a 8 categorie.',
      'zh': '免费版：最多 8 个分类。',
      'hi': 'मुफ़्त संस्करण: अधिकतम 8 श्रेणियाँ।',
      'ar': 'النسخة المجانية: حتى 8 فئات كحد أقصى.',
      'ru': 'Бесплатная версия: до 8 категорий.',
    },
    'premiumLimitProducts': {
      'es': 'Versión gratuita: máximo 15 productos por categoría.',
      'en': 'Free version: up to 15 products per category.',
      'pt': 'Versão gratuita: até 15 produtos por categoria.',
      'fr': 'Version gratuite : jusqu’à 15 produits par catégorie.',
      'de': 'Kostenlose Version: bis zu 15 Produkte pro Kategorie.',
      'it': 'Versione gratuita: fino a 15 prodotti per categoria.',
      'zh': '免费版：每个分类最多 15 个商品。',
      'hi': 'मुफ़्त संस्करण: प्रति श्रेणी अधिकतम 15 उत्पाद।',
      'ar': 'النسخة المجانية: حتى 15 منتجًا لكل فئة كحد أقصى.',
      'ru': 'Бесплатная версия: до 15 товаров в категории.',
    },
    'purchaseSuccess': {
      'es': '¡Gracias por apoyar la app!', 'en': 'Thanks for supporting the app!',
      'pt': 'Obrigado por apoiar o app!', 'fr': 'Merci de soutenir l’application !',
      'de': 'Danke für die Unterstützung!', 'it': 'Grazie per il supporto!',
      'zh': '感谢支持！', 'hi': 'ऐप को सपोर्ट करने के लिए धन्यवाद!', 'ar': 'شكرًا لدعمك التطبيق!',
      'ru': 'Спасибо за поддержку приложения!',
    },
    'purchaseError': {
      'es': 'No se pudo completar la compra', 'en': 'Could not complete the purchase',
      'pt': 'Não foi possível concluir a compra', 'fr': 'Impossible de finaliser l’achat',
      'de': 'Kauf konnte nicht abgeschlossen werden', 'it': 'Impossibile completare l’acquisto',
      'zh': '购买未完成', 'hi': 'खरीद पूरी नहीं हो सकी', 'ar': 'تعذّر إتمام الشراء',
      'ru': 'Не удалось завершить покупку',
    },
    'purchasePending': {
      'es': 'Compra pendiente de confirmación…', 'en': 'Purchase pending confirmation…',
      'pt': 'Compra pendente de confirmação…', 'fr': 'Achat en attente de confirmation…',
      'de': 'Kauf wartet auf Bestätigung…', 'it': 'Acquisto in attesa di conferma…',
      'zh': '购买待确认…', 'hi': 'खरीद की पुष्टि लंबित…', 'ar': 'الشراء قيد التأكيد…',
      'ru': 'Покупка ожидает подтверждения…',
    },
    'premiumBenefitCollaborators': {
      'es': 'Invita y gestiona colaboradores', 'en': 'Invite and manage collaborators',
      'pt': 'Convide e gerencie colaboradores', 'fr': 'Invitez et gérez des collaborateurs',
      'de': 'Mitarbeiter einladen und verwalten', 'it': 'Invita e gestisci collaboratori',
      'zh': '邀请和管理协作者', 'hi': 'सहयोगियों को आमंत्रित और प्रबंधित करें',
      'ar': 'دعوة المتعاونين وإدارتهم', 'ru': 'Приглашайте участников и управляйте ими',
    },
    'premiumBenefitDarkMode': {
      'es': 'Modo oscuro', 'en': 'Dark mode', 'pt': 'Modo escuro', 'fr': 'Mode sombre',
      'de': 'Dunkelmodus', 'it': 'Modalità scura', 'zh': '深色模式', 'hi': 'डार्क मोड',
      'ar': 'الوضع الداكن', 'ru': 'Тёмная тема',
    },
    'premiumBenefitGalleryView': {
      'es': 'Vista en galería', 'en': 'Gallery view', 'pt': 'Visualização em galeria',
      'fr': 'Vue galerie', 'de': 'Galerieansicht', 'it': 'Vista galleria',
      'zh': '图库视图', 'hi': 'गैलरी दृश्य', 'ar': 'عرض المعرض', 'ru': 'Вид галереи',
    },
    'premiumLimitCollaborators': {
      'es': 'Con Premium puedes invitar y gestionar colaboradores.',
      'en': 'With Premium you can invite and manage collaborators.',
      'pt': 'Com o Premium você pode convidar e gerenciar colaboradores.',
      'fr': 'Avec Premium, vous pouvez inviter et gérer des collaborateurs.',
      'de': 'Mit Premium kannst du Mitarbeiter einladen und verwalten.',
      'it': 'Con Premium puoi invitare e gestire i collaboratori.',
      'zh': '升级高级版即可邀请和管理协作者。',
      'hi': 'प्रीमियम के साथ आप सहयोगियों को आमंत्रित और प्रबंधित कर सकते हैं।',
      'ar': 'مع النسخة المميزة يمكنك دعوة المتعاونين وإدارتهم.',
      'ru': 'С Premium вы можете приглашать участников и управлять ими.',
    },
    'premiumFeatureExclusive': {
      'es': 'Esta función es exclusiva de Premium.',
      'en': 'This feature is exclusive to Premium.',
      'pt': 'Este recurso é exclusivo do Premium.',
      'fr': 'Cette fonction est exclusive à Premium.',
      'de': 'Diese Funktion ist Premium vorbehalten.',
      'it': 'Questa funzione è esclusiva di Premium.',
      'zh': '此功能为高级版专属。',
      'hi': 'यह सुविधा केवल प्रीमियम के लिए है।',
      'ar': 'هذه الميزة حصرية للنسخة المميزة.',
      'ru': 'Эта функция доступна только в Premium.',
    },
    'plusTitle': {
      'es': 'Hazte Premium Plus', 'en': 'Go Premium Plus', 'pt': 'Torne-se Premium Plus',
      'fr': 'Passer à Premium Plus', 'de': 'Premium Plus werden', 'it': 'Diventa Premium Plus',
      'zh': '升级 Premium Plus', 'hi': 'प्रीमियम प्लस बनें', 'ar': 'الاشتراك في Premium Plus', 'ru': 'Перейти на Premium Plus',
    },
    'plusPriceFallback': {
      'es': '2,99 €', 'en': '€2.99', 'pt': '2,99 €', 'fr': '2,99 €', 'de': '2,99 €',
      'it': '2,99 €', 'zh': '2.99欧元', 'hi': '2.99 यूरो', 'ar': '2.99 يورو', 'ru': '2,99 евро',
    },
    'plusActive': {
      'es': 'Ya tienes Premium Plus', 'en': 'You already have Premium Plus', 'pt': 'Você já tem Premium Plus',
      'fr': 'Vous avez déjà Premium Plus', 'de': 'Du hast bereits Premium Plus', 'it': 'Hai già Premium Plus',
      'zh': '你已是 Premium Plus', 'hi': 'आपके पास पहले से प्रीमियम प्लस है', 'ar': 'لديك Premium Plus بالفعل',
      'ru': 'У вас уже есть Premium Plus',
    },
    'unlockPlusFor': {
      'es': 'Hazte Premium Plus por {price}', 'en': 'Get Premium Plus for {price}',
      'pt': 'Torne-se Premium Plus por {price}', 'fr': 'Passez à Premium Plus pour {price}',
      'de': 'Premium Plus für {price}', 'it': 'Passa a Premium Plus per {price}',
      'zh': '{price} 升级为 Premium Plus', 'hi': '{price} में प्रीमियम प्लस बनें',
      'ar': 'اشترك في Premium Plus مقابل {price}', 'ru': 'Перейти на Premium Plus за {price}',
    },
    'plusBenefitExport': {
      'es': 'Exporta la lista de Comprar en PDF o imagen',
      'en': 'Export your shopping list as PDF or image',
      'pt': 'Exporte a lista de Compras em PDF ou imagem',
      'fr': 'Exportez votre liste de courses en PDF ou image',
      'de': 'Exportiere deine Einkaufsliste als PDF oder Bild',
      'it': 'Esporta la lista della spesa in PDF o immagine',
      'zh': '将购物清单导出为 PDF 或图片',
      'hi': 'अपनी खरीदारी सूची को PDF या छवि में निर्यात करें',
      'ar': 'صدّر قائمة التسوق بصيغة PDF أو صورة',
      'ru': 'Экспортируйте список покупок в PDF или изображение',
    },
    'plusBenefitSubcategories': {
      'es': 'Subcategorías para organizar mejor',
      'en': 'Subcategories to organize better',
      'pt': 'Subcategorias para organizar melhor',
      'fr': 'Sous-catégories pour mieux organiser',
      'de': 'Unterkategorien für bessere Ordnung',
      'it': 'Sottocategorie per organizzare meglio',
      'zh': '子分类，整理更清晰',
      'hi': 'बेहतर व्यवस्था के लिए उपश्रेणियाँ',
      'ar': 'فئات فرعية لتنظيم أفضل',
      'ru': 'Подкатегории для лучшей организации',
    },
    'plusBenefitNotifications': {
      'es': 'Notificaciones de tus compras',
      'en': 'Shopping notifications',
      'pt': 'Notificações das suas compras',
      'fr': 'Notifications de vos achats',
      'de': 'Benachrichtigungen zu deinen Einkäufen',
      'it': 'Notifiche dei tuoi acquisti',
      'zh': '购物通知',
      'hi': 'खरीदारी सूचनाएँ',
      'ar': 'إشعارات المشتريات',
      'ru': 'Уведомления о покупках',
    },
    'plusBenefitSuggestions': {
      'es': 'Sugerencias de productos que se agotan',
      'en': 'Smart suggestions for running-out products',
      'pt': 'Sugestões de produtos que estão acabando',
      'fr': 'Suggestions de produits qui s’épuisent',
      'de': 'Vorschläge für auslaufende Produkte',
      'it': 'Suggerimenti di prodotti in esaurimento',
      'zh': '智能提示快用完的商品',
      'hi': 'समाप्त हो रहे उत्पादों की सुझाव',
      'ar': 'اقتراحات للمنتجات التي تنفد',
      'ru': 'Подсказки о заканчивающихся товарах',
    },
    'plusBenefitCollaborators': {
      'es': 'Hasta 4 colaboradores', 'en': 'Up to 4 collaborators', 'pt': 'Até 4 colaboradores',
      'fr': 'Jusqu’à 4 collaborateurs', 'de': 'Bis zu 4 Mitarbeiter', 'it': 'Fino a 4 collaboratori',
      'zh': '最多 4 名协作者', 'hi': 'अधिकतम 4 सहयोगी', 'ar': 'حتى 4 متعاونون', 'ru': 'До 4 участников',
    },
    'plusExclusive': {
      'es': 'Esta función es exclusiva de Premium Plus.',
      'en': 'This feature is exclusive to Premium Plus.',
      'pt': 'Este recurso é exclusivo do Premium Plus.',
      'fr': 'Cette fonction est exclusive à Premium Plus.',
      'de': 'Diese Funktion ist Premium Plus vorbehalten.',
      'it': 'Questa funzione è esclusiva di Premium Plus.',
      'zh': '此功能为 Premium Plus 专属。',
      'hi': 'यह सुविधा केवल प्रीमियम प्लस के लिए है।',
      'ar': 'هذه الميزة حصرية لـ Premium Plus.',
      'ru': 'Эта функция доступна только в Premium Plus.',
    },
    'quantityLabel': {
      'es': 'Cantidad', 'en': 'Quantity', 'pt': 'Quantidade',
      'fr': 'Quantité', 'de': 'Menge', 'it': 'Quantità',
      'zh': '数量', 'hi': 'मात्रा', 'ar': 'الكمية', 'ru': 'Количество',
    },
    'unitLabel': {
      'es': 'Unidad', 'en': 'Unit', 'pt': 'Unidade',
      'fr': 'Unité', 'de': 'Einheit', 'it': 'Unità',
      'zh': '单位', 'hi': 'इकाई', 'ar': 'الوحدة', 'ru': 'Единица',
    },
    'forgotPassword': {
      'es': '¿Olvidaste la contraseña?', 'en': 'Forgot password?',
      'pt': 'Esqueceu a senha?', 'fr': 'Mot de passe oublié ?',
      'de': 'Passwort vergessen?', 'it': 'Password dimenticata?',
      'zh': '忘记密码？', 'hi': 'पासवर्ड भूल गए?',
      'ar': 'نسيت كلمة المرور؟', 'ru': 'Забыли пароль?',
    },
    'resetPasswordTitle': {
      'es': 'Restablecer contraseña', 'en': 'Reset password',
      'pt': 'Redefinir senha', 'fr': 'Réinitialiser le mot de passe',
      'de': 'Passwort zurücksetzen', 'it': 'Reimposta password',
      'zh': '重置密码', 'hi': 'पासवर्ड रीसेट करें',
      'ar': 'إعادة تعيين كلمة المرور', 'ru': 'Сбросить пароль',
    },
    'resetPasswordSubtitle': {
      'es': 'Te enviaremos un correo con un enlace para crear una nueva contraseña.',
      'en': "We'll email you a link to create a new password.",
      'pt': 'Enviaremos um e-mail com um link para criar uma nova senha.',
      'fr': "Nous vous enverrons un lien par e-mail pour créer un nouveau mot de passe.",
      'de': 'Wir senden Ihnen einen Link per E-Mail, um ein neues Passwort zu erstellen.',
      'it': "Ti invieremo un'email con un link per creare una nuova password.",
      'zh': '我们会发邮件给你，附上创建新密码的链接。',
      'hi': 'हम आपको एक नया पासवर्ड बनाने के लिए एक लिंक ईमेल करेंगे।',
      'ar': 'سنرسل لك بريدًا إلكترونيًا يحتوي على رابط لإنشاء كلمة مرور جديدة.',
      'ru': 'Мы отправим вам ссылку для создания нового пароля.',
    },
    'resetPasswordButton': {
      'es': 'Enviar correo', 'en': 'Send email',
      'pt': 'Enviar e-mail', 'fr': 'Envoyer',
      'de': 'E-Mail senden', 'it': 'Invia email',
      'zh': '发送邮件', 'hi': 'ईमेल भेजें',
      'ar': 'إرسال البريد', 'ru': 'Отправить',
    },
    'resetPasswordSuccess': {
      'es': 'Correo enviado. Revisa tu bandeja de entrada.',
      'en': 'Email sent. Check your inbox.',
      'pt': 'E-mail enviado. Verifique sua caixa de entrada.',
      'fr': 'E-mail envoyé. Vérifiez votre boîte de réception.',
      'de': 'E-Mail gesendet. Überprüfen Sie Ihren Posteingang.',
      'it': "Email inviata. Controlla la tua casella di posta.",
      'zh': '邮件已发送，请查收收件箱。',
      'hi': 'ईमेल भेज दिया गया। अपना इनबॉक्स देखें।',
      'ar': 'تم إرسال البريد. تحقق من صندوق الوارد.',
      'ru': 'Письмо отправлено. Проверьте входящие.',
    },
    'permissionDenied': {
      'es': 'No tienes permiso para esta acción.',
      'en': 'You don\'t have permission for this action.',
      'pt': 'Você não tem permissão para esta ação.',
      'fr': 'Vous n\'avez pas la permission pour cette action.',
      'de': 'Sie haben keine Berechtigung für diese Aktion.',
      'it': 'Non hai il permesso per questa azione.',
      'zh': '您没有权限执行此操作。',
      'hi': 'आपके पास इस क्रिया की अनुमति नहीं है।',
      'ar': 'ليس لديك صلاحية لهذا الإجراء.',
      'ru': 'У вас нет разрешения на это действие.',
    },
    // Recordatorio inteligente de compras + centro de notificaciones in-app
    // (Premium Plus). Traducidas es/en; el resto cae a español por el
    // fallback de _s(), igual que otras claves nuevas del proyecto.
    'notifications': {'es': 'Notificaciones', 'en': 'Notifications'},
    'notificationCenterEmpty': {
      'es': 'Aún no tienes notificaciones. Te avisaremos cuando sea buen momento para ir de compras.',
      'en': 'No notifications yet. We\'ll let you know when it\'s a good time to go shopping.',
    },
    'markAllRead': {'es': 'Marcar todo como leído', 'en': 'Mark all as read'},
    'shoppingReminderTitle': {'es': '¿Vamos de compras? 🛒', 'en': 'Time to go shopping? 🛒'},
    'shoppingReminderBody': {
      'es': 'Según tus compras habituales, se te debe estar acabando: {items}. Toca para agregarlos a tu lista.',
      'en': 'Based on your usual shopping, you\'re probably running low on: {items}. Tap to add them to your list.',
    },
    'suggestedProductsTitle': {'es': 'Productos habituales', 'en': 'Usual products'},
    'suggestedProductsSubtitle': {
      'es': 'Elige lo que quieras agregar a tu lista de compras.',
      'en': 'Choose what you want to add to your shopping list.',
    },
    'addSuggestedToList': {'es': 'Agregar a la lista', 'en': 'Add to list'},
    'suggestionsAddedSuccess': {
      'es': 'Productos agregados a tu lista de compras',
      'en': 'Products added to your shopping list',
    },
    'noActiveSuggestion': {
      'es': 'Esta sugerencia ya no está disponible.',
      'en': 'This suggestion is no longer available.',
    },
    'notificationsRequirePlus': {
      'es': 'Los recordatorios inteligentes de compra son exclusivos de Premium Plus.',
      'en': 'Smart shopping reminders are exclusive to Premium Plus.',
    },
    'suggestionAddMoreItems': {
      'es': 'Agregar más productos',
      'en': 'Add more products',
    },
    'suggestionSearchHint': {
      'es': 'Buscar producto…',
      'en': 'Search products…',
    },
    'suggestionEdit': {'es': 'Editar cantidad', 'en': 'Edit quantity'},
    'suggestionEditHint': {
      'es': 'Toca el lápiz para cambiar la cantidad',
      'en': 'Tap the pencil to change the quantity',
    },
    'suggestionQuantityEmpty': {'es': 'Sin cantidad', 'en': 'No quantity'},
    'suggestionNoResults': {'es': 'Sin resultados', 'en': 'No results'},
  };

  static const Map<String, Map<String, String>> _names = {
    'Kitchen': {'es': 'Cocina', 'en': 'Kitchen', 'pt': 'Cozinha', 'fr': 'Cuisine', 'de': 'Küche', 'it': 'Cucina', 'zh': '厨房', 'hi': 'रसोई', 'ar': 'المطبخ', 'ru': 'Кухня'},
    'Personal care': {'es': 'Cuidado personal', 'en': 'Personal care', 'pt': 'Cuidados pessoais', 'fr': 'Soins personnels', 'de': 'Körperpflege', 'it': 'Igiene personale', 'zh': '个人护理', 'hi': 'व्यक्तिगत देखभाल', 'ar': 'العناية الشخصية', 'ru': 'Личная гигиена'},
    'Cleaning': {'es': 'Limpieza', 'en': 'Cleaning', 'pt': 'Limpeza', 'fr': 'Ménage', 'de': 'Reinigung', 'it': 'Pulizia', 'zh': '清洁用品', 'hi': 'सफाई', 'ar': 'التنظيف', 'ru': 'Чистящие средства'},
    'Meats': {'es': 'Carnes', 'en': 'Meats', 'pt': 'Carnes', 'fr': 'Viandes', 'de': 'Fleisch', 'it': 'Carni', 'zh': '肉类', 'hi': 'मांस', 'ar': 'اللحوم', 'ru': 'Мясо'},
    'Drinks': {'es': 'Bebidas', 'en': 'Drinks', 'pt': 'Bebidas', 'fr': 'Boissons', 'de': 'Getränke', 'it': 'Bevande', 'zh': '饮料', 'hi': 'पेय', 'ar': 'المشروبات', 'ru': 'Напитки'},
    'Breakfast': {'es': 'Desayuno', 'en': 'Breakfast', 'pt': 'Pequeno-almoço', 'fr': 'Petit-déjeuner', 'de': 'Frühstück', 'it': 'Colazione', 'zh': '早餐', 'hi': 'नाश्ता', 'ar': 'الفطور', 'ru': 'Завтрак'},
    'Fruits': {'es': 'Frutas', 'en': 'Fruits', 'pt': 'Frutas', 'fr': 'Fruits', 'de': 'Obst', 'it': 'Frutta', 'zh': '水果', 'hi': 'फल', 'ar': 'الفواكه', 'ru': 'Фрукты'},
    'Vegetables': {'es': 'Verduras', 'en': 'Vegetables', 'pt': 'Legumes', 'fr': 'Légumes', 'de': 'Gemüse', 'it': 'Verdura', 'zh': '蔬菜', 'hi': 'सब्ज़ियाँ', 'ar': 'الخضروات', 'ru': 'Овощи'},
    'Baby': {'es': 'Bebé', 'en': 'Baby', 'pt': 'Bebê', 'fr': 'Bébé', 'de': 'Baby', 'it': 'Bebè', 'zh': '婴儿', 'hi': 'शिशु', 'ar': 'طفل', 'ru': 'Детское'},
    'Milk': {'es': 'Leche', 'en': 'Milk', 'pt': 'Leite', 'fr': 'Lait', 'de': 'Milch', 'it': 'Latte', 'zh': '牛奶', 'hi': 'दूध', 'ar': 'حليب', 'ru': 'Молоко'},
    'Bread': {'es': 'Pan', 'en': 'Bread', 'pt': 'Pão', 'fr': 'Pain', 'de': 'Brot', 'it': 'Pane', 'zh': '面包', 'hi': 'ब्रेड', 'ar': 'خبز', 'ru': 'Хлеб'},
    'Cheese': {'es': 'Queso', 'en': 'Cheese', 'pt': 'Queijo', 'fr': 'Fromage', 'de': 'Käse', 'it': 'Formaggio', 'zh': '奶酪', 'hi': 'चीज़', 'ar': 'جبن', 'ru': 'Сыр'},
    'Eggs': {'es': 'Huevos', 'en': 'Eggs', 'pt': 'Ovos', 'fr': 'Œufs', 'de': 'Eier', 'it': 'Uova', 'zh': '鸡蛋', 'hi': 'अंडे', 'ar': 'بيض', 'ru': 'Яйца'},
    'Rice': {'es': 'Arroz', 'en': 'Rice', 'pt': 'Arroz', 'fr': 'Riz', 'de': 'Reis', 'it': 'Riso', 'zh': '大米', 'hi': 'चावल', 'ar': 'أرز', 'ru': 'Рис'},
    'Pasta': {'es': 'Pasta', 'en': 'Pasta', 'pt': 'Massa', 'fr': 'Pâtes', 'de': 'Nudeln', 'it': 'Pasta', 'zh': '意面', 'hi': 'पास्ता', 'ar': 'معكرونة', 'ru': 'Паста'},
    'Spaghetti': {'es': 'Espaguetis', 'en': 'Spaghetti', 'pt': 'Espaguete', 'fr': 'Spaghetti', 'de': 'Spaghetti', 'it': 'Spaghetti', 'zh': '意大利面', 'hi': 'स्पेगेटी', 'ar': 'سباغيتي', 'ru': 'Спагетти'},
    'Tomato puree': {'es': 'Puré de tomate', 'en': 'Tomato puree', 'pt': 'Polpa de tomate', 'fr': 'Purée de tomate', 'de': 'Tomatenmark', 'it': 'Passata di pomodoro', 'zh': '番茄酱', 'hi': 'टमाटर प्यूरी', 'ar': 'معجون الطماطم', 'ru': 'Томатное пюре'},
    'Vinegar': {'es': 'Vinagre', 'en': 'Vinegar', 'pt': 'Vinagre', 'fr': 'Vinaigre', 'de': 'Essig', 'it': 'Aceto', 'zh': '醋', 'hi': 'सिरका', 'ar': 'خل', 'ru': 'Уксус'},
    'Chicken': {'es': 'Pollo', 'en': 'Chicken', 'pt': 'Frango', 'fr': 'Poulet', 'de': 'Hähnchen', 'it': 'Pollo', 'zh': '鸡肉', 'hi': 'चिकन', 'ar': 'دجاج', 'ru': 'Курица'},
    'Beef': {'es': 'Carne de res', 'en': 'Beef', 'pt': 'Carne bovina', 'fr': 'Bœuf', 'de': 'Rindfleisch', 'it': 'Manzo', 'zh': '牛肉', 'hi': 'गोमांस', 'ar': 'لحم بقري', 'ru': 'Говядина'},
    'Fish': {'es': 'Pescado', 'en': 'Fish', 'pt': 'Peixe', 'fr': 'Poisson', 'de': 'Fisch', 'it': 'Pesce', 'zh': '鱼', 'hi': 'मछली', 'ar': 'سمك', 'ru': 'Рыба'},
    'Apple': {'es': 'Manzana', 'en': 'Apple', 'pt': 'Maçã', 'fr': 'Pomme', 'de': 'Apfel', 'it': 'Mela', 'zh': '苹果', 'hi': 'सेब', 'ar': 'تفاح', 'ru': 'Яблоко'},
    'Banana': {'es': 'Plátano', 'en': 'Banana', 'pt': 'Banana', 'fr': 'Banane', 'de': 'Banane', 'it': 'Banana', 'zh': '香蕉', 'hi': 'केला', 'ar': 'موز', 'ru': 'Банан'},
    'Orange': {'es': 'Naranja', 'en': 'Orange', 'pt': 'Laranja', 'fr': 'Orange', 'de': 'Orange', 'it': 'Arancia', 'zh': '橙子', 'hi': 'संतरा', 'ar': 'برتقال', 'ru': 'Апельсин'},
    'Lemon': {'es': 'Limón', 'en': 'Lemon', 'pt': 'Limão', 'fr': 'Citron', 'de': 'Zitrone', 'it': 'Limone', 'zh': '柠檬', 'hi': 'नींबू', 'ar': 'ليمون', 'ru': 'Лимон'},
    'Tomato': {'es': 'Tomate', 'en': 'Tomato', 'pt': 'Tomate', 'fr': 'Tomate', 'de': 'Tomate', 'it': 'Pomodoro', 'zh': '番茄', 'hi': 'टमाटर', 'ar': 'طماطم', 'ru': 'Помидор'},
    'Potato': {'es': 'Patata', 'en': 'Potato', 'pt': 'Batata', 'fr': 'Pomme de terre', 'de': 'Kartoffel', 'it': 'Patata', 'zh': '土豆', 'hi': 'आलू', 'ar': 'بطاطس', 'ru': 'Картофель'},
    'Onion': {'es': 'Cebolla', 'en': 'Onion', 'pt': 'Cebola', 'fr': 'Oignon', 'de': 'Zwiebel', 'it': 'Cipolla', 'zh': '洋葱', 'hi': 'प्याज़', 'ar': 'بصل', 'ru': 'Лук'},
    'Carrot': {'es': 'Zanahoria', 'en': 'Carrot', 'pt': 'Cenoura', 'fr': 'Carotte', 'de': 'Karotte', 'it': 'Carota', 'zh': '胡萝卜', 'hi': 'गाजर', 'ar': 'جزر', 'ru': 'Морковь'},
    'Strawberry': {'es': 'Fresa', 'en': 'Strawberry', 'pt': 'Morango', 'fr': 'Fraise', 'de': 'Erdbeere', 'it': 'Fragola', 'zh': '草莓', 'hi': 'स्ट्रॉबेरी', 'ar': 'فراولة', 'ru': 'Клубника'},
    'Grapes': {'es': 'Uvas', 'en': 'Grapes', 'pt': 'Uvas', 'fr': 'Raisins', 'de': 'Trauben', 'it': 'Uva', 'zh': '葡萄', 'hi': 'अंगूर', 'ar': 'عنب', 'ru': 'Виноград'},
    'Watermelon': {'es': 'Sandía', 'en': 'Watermelon', 'pt': 'Melancia', 'fr': 'Pastèque', 'de': 'Wassermelone', 'it': 'Anguria', 'zh': '西瓜', 'hi': 'तरबूज', 'ar': 'بطيخ', 'ru': 'Арбуз'},
    'Avocado': {'es': 'Aguacate', 'en': 'Avocado', 'pt': 'Abacate', 'fr': 'Avocat', 'de': 'Avocado', 'it': 'Avocado', 'zh': '牛油果', 'hi': 'एवोकाडो', 'ar': 'أفوكادو', 'ru': 'Авокадо'},
    'Coffee': {'es': 'Café', 'en': 'Coffee', 'pt': 'Café', 'fr': 'Café', 'de': 'Kaffee', 'it': 'Caffè', 'zh': '咖啡', 'hi': 'कॉफ़ी', 'ar': 'قهوة', 'ru': 'Кофе'},
    'Sugar': {'es': 'Azúcar', 'en': 'Sugar', 'pt': 'Açúcar', 'fr': 'Sucre', 'de': 'Zucker', 'it': 'Zucchero', 'zh': '糖', 'hi': 'चीनी', 'ar': 'سكر', 'ru': 'Сахар'},
    'Salt': {'es': 'Sal', 'en': 'Salt', 'pt': 'Sal', 'fr': 'Sel', 'de': 'Salz', 'it': 'Sale', 'zh': '盐', 'hi': 'नमक', 'ar': 'ملح', 'ru': 'Соль'},
    'Oil': {'es': 'Aceite', 'en': 'Oil', 'pt': 'Óleo', 'fr': 'Huile', 'de': 'Öl', 'it': 'Olio', 'zh': '食用油', 'hi': 'तेल', 'ar': 'زيت', 'ru': 'Масло'},
    'Butter': {'es': 'Mantequilla', 'en': 'Butter', 'pt': 'Manteiga', 'fr': 'Beurre', 'de': 'Butter', 'it': 'Burro', 'zh': '黄油', 'hi': 'मक्खन', 'ar': 'زبدة', 'ru': 'Сливочное масло'},
    'Cream cheese': {'es': 'Queso crema', 'en': 'Cream cheese', 'pt': 'Requeijão', 'fr': 'Fromage à tartiner', 'de': 'Frischkäse', 'it': 'Formaggio spalmabile', 'zh': '奶油奶酪', 'hi': 'क्रीम चीज़', 'ar': 'جبنة كريمية', 'ru': 'Сливочный сыр'},
    'Yogurt': {'es': 'Yogur', 'en': 'Yogurt', 'pt': 'Iogurte', 'fr': 'Yaourt', 'de': 'Joghurt', 'it': 'Yogurt', 'zh': '酸奶', 'hi': 'दही', 'ar': 'زبادي', 'ru': 'Йогурт'},
    'Honey': {'es': 'Miel', 'en': 'Honey', 'pt': 'Mel', 'fr': 'Miel', 'de': 'Honig', 'it': 'Miele', 'zh': '蜂蜜', 'hi': 'शहद', 'ar': 'عسل', 'ru': 'Мёд'},
    'Chocolate': {'es': 'Chocolate', 'en': 'Chocolate', 'pt': 'Chocolate', 'fr': 'Chocolat', 'de': 'Schokolade', 'it': 'Cioccolato', 'zh': '巧克力', 'hi': 'चॉकलेट', 'ar': 'شوكولاتة', 'ru': 'Шоколад'},
    'Cookies': {'es': 'Galletas', 'en': 'Cookies', 'pt': 'Biscoitos', 'fr': 'Biscuits', 'de': 'Kekse', 'it': 'Biscotti', 'zh': '饼干', 'hi': 'बिस्कुट', 'ar': 'بسكويت', 'ru': 'Печенье'},
    'Juice': {'es': 'Jugo', 'en': 'Juice', 'pt': 'Suco', 'fr': 'Jus', 'de': 'Saft', 'it': 'Succo', 'zh': '果汁', 'hi': 'जूस', 'ar': 'عصير', 'ru': 'Сок'},
    'Water': {'es': 'Agua', 'en': 'Water', 'pt': 'Água', 'fr': 'Eau', 'de': 'Wasser', 'it': 'Acqua', 'zh': '水', 'hi': 'पानी', 'ar': 'ماء', 'ru': 'Вода'},
    'Toilet paper': {'es': 'Papel higiénico', 'en': 'Toilet paper', 'pt': 'Papel higiénico', 'fr': 'Papier toilette', 'de': 'Klopapier', 'it': 'Carta igienica', 'zh': '卫生纸', 'hi': 'टॉयलेट पेपर', 'ar': 'ورق تواليت', 'ru': 'Туалетная бумага'},
    'Soap': {'es': 'Jabón', 'en': 'Soap', 'pt': 'Sabonete', 'fr': 'Savon', 'de': 'Seife', 'it': 'Sapone', 'zh': '肥皂', 'hi': 'साबुन', 'ar': 'صابون', 'ru': 'Мыло'},
    'Detergent': {'es': 'Detergente', 'en': 'Detergent', 'pt': 'Detergente', 'fr': 'Détergent', 'de': 'Waschmittel', 'it': 'Detersivo', 'zh': '洗涤剂', 'hi': 'डिटर्जेंट', 'ar': 'منظف', 'ru': 'Стиральный порошок'},
    'Shampoo': {'es': 'Champú', 'en': 'Shampoo', 'pt': 'Shampoo', 'fr': 'Shampooing', 'de': 'Shampoo', 'it': 'Shampoo', 'zh': '洗发水', 'hi': 'शैम्पू', 'ar': 'شامبو', 'ru': 'Шампунь'},
    'Toothpaste': {'es': 'Pasta de dientes', 'en': 'Toothpaste', 'pt': 'Creme dental', 'fr': 'Dentifrice', 'de': 'Zahnpasta', 'it': 'Dentifricio', 'zh': '牙膏', 'hi': 'टूथपेस्ट', 'ar': 'معجون أسنان', 'ru': 'Зубная паста'},
    'Apples': {'es': 'Manzanas', 'en': 'Apples', 'pt': 'Maçãs', 'fr': 'Pommes', 'de': 'Äpfel', 'it': 'Mele', 'zh': '苹果', 'hi': 'सेब', 'ar': 'تفاح', 'ru': 'Яблоки'},
    'Ball bread': {'es': 'Pan de bola', 'en': 'Ball bread', 'pt': 'Pão de bola', 'fr': 'Pain boule', 'de': 'Kugelbrot', 'it': 'Pane a sfera', 'zh': '圆面包', 'hi': 'गोल ब्रेड', 'ar': 'خبز كروي', 'ru': 'Шаровой хлеб'},
    'Beet': {'es': 'Remolacha', 'en': 'Beet', 'pt': 'Beterraba', 'fr': 'Betterave', 'de': 'Rote Bete', 'it': 'Barbabietola', 'zh': '甜菜', 'hi': 'चुकंदर', 'ar': 'بنجر', 'ru': 'Свёкла'},
    'Black beans': {'es': 'Frijoles negros', 'en': 'Black beans', 'pt': 'Feijão preto', 'fr': 'Haricots noirs', 'de': 'Schwarze Bohnen', 'it': 'Fagioli neri', 'zh': '黑豆', 'hi': 'काली बीन्स', 'ar': 'فاصوليا سوداء', 'ru': 'Чёрная фасоль'},
    'Chickpea': {'es': 'Garbanzos', 'en': 'Chickpea', 'pt': 'Grão-de-bico', 'fr': 'Pois chiche', 'de': 'Kichererbse', 'it': 'Ceci', 'zh': '鹰嘴豆', 'hi': 'चना', 'ar': 'حمص', 'ru': 'Нут'},
    'Cow': {'es': 'Vaca', 'en': 'Cow', 'pt': 'Boi', 'fr': 'Bœuf', 'de': 'Rind', 'it': 'Manzo', 'zh': '牛肉', 'hi': 'गोमांस', 'ar': 'لحم بقر', 'ru': 'Говядина'},
    'Croissant': {'es': 'Cruasán', 'en': 'Croissant', 'pt': 'Croissant', 'fr': 'Croissant', 'de': 'Croissant', 'it': 'Cornetto', 'zh': '牛角包', 'hi': 'क्रोइसैन', 'ar': 'كرواسون', 'ru': 'Круассан'},
    'Cucumber': {'es': 'Pepino', 'en': 'Cucumber', 'pt': 'Pepino', 'fr': 'Concombre', 'de': 'Gurke', 'it': 'Cetriolo', 'zh': '黄瓜', 'hi': 'खीरा', 'ar': 'خيار', 'ru': 'Огурец'},
    'Lettuce': {'es': 'Lechuga', 'en': 'Lettuce', 'pt': 'Alface', 'fr': 'Laitue', 'de': 'Kopfsalat', 'it': 'Lattuga', 'zh': '生菜', 'hi': 'सलाद', 'ar': 'خس', 'ru': 'Салат'},
    'Mini baguette': {'es': 'Mini bagueta', 'en': 'Mini baguette', 'pt': 'Mini baguete', 'fr': 'Mini baguette', 'de': 'Mini-Baguette', 'it': 'Mini baguette', 'zh': '小法棍', 'hi': 'मिनी बैगेट', 'ar': 'baguette صغيرة', 'ru': 'Мини-багет'},
    'Pork': {'es': 'Cerdo', 'en': 'Pork', 'pt': 'Porco', 'fr': 'Porc', 'de': 'Schweinefleisch', 'it': 'Maiale', 'zh': '猪肉', 'hi': 'सूअर का मांस', 'ar': 'لحم خنزير', 'ru': 'Свинина'},
    'Salmon': {'es': 'Salmón', 'en': 'Salmon', 'pt': 'Salmão', 'fr': 'Saumon', 'de': 'Lachs', 'it': 'Salmone', 'zh': '三文鱼', 'hi': 'सैल्मन', 'ar': 'سلمون', 'ru': 'Лосось'},
    'Tomatoes': {'es': 'Tomates', 'en': 'Tomatoes', 'pt': 'Tomates', 'fr': 'Tomates', 'de': 'Tomaten', 'it': 'Pomodori', 'zh': '番茄', 'hi': 'टमाटर', 'ar': 'طماطم', 'ru': 'Помидоры'},
    'White grapes': {'es': 'Uvas blancas', 'en': 'White grapes', 'pt': 'Uvas brancas', 'fr': 'Raisins blancs', 'de': 'Weiße Trauben', 'it': 'Uve bianche', 'zh': '白葡萄', 'hi': 'सफेद अंगूर', 'ar': 'عنب أبيض', 'ru': 'Белый виноград'},
    'Garlic': {'es': 'Ajo', 'en': 'Garlic', 'pt': 'Alho', 'fr': 'Ail', 'de': 'Knoblauch', 'it': 'Aglio', 'zh': '大蒜', 'hi': 'लहसुन', 'ar': 'ثوم', 'ru': 'Чеснок'},
    'Bell pepper': {'es': 'Pimiento', 'en': 'Bell pepper', 'pt': 'Pimento', 'fr': 'Poivron', 'de': 'Paprika', 'it': 'Peperone', 'zh': '甜椒', 'hi': 'शिमला मिर्च', 'ar': 'فلفل حلو', 'ru': 'Болгарский перец'},
    'Olive oil': {'es': 'Aceite de oliva', 'en': 'Olive oil', 'pt': 'Azeite de oliva', 'fr': "Huile d'olive", 'de': 'Olivenöl', 'it': 'Olio d\'oliva', 'zh': '橄榄油', 'hi': 'जैतून का तेल', 'ar': 'زيت زيتون', 'ru': 'Оливковое масло'},
    'Red onion': {'es': 'Cebolla roja', 'en': 'Red onion', 'pt': 'Cebola roxa', 'fr': 'Oignon rouge', 'de': 'Rote Zwiebel', 'it': 'Cipolla rossa', 'zh': '红洋葱', 'hi': 'लाल प्याज़', 'ar': 'بصل أحمر', 'ru': 'Красный лук'},
    'Sunflower oil': {'es': 'Aceite de girasol', 'en': 'Sunflower oil', 'pt': 'Óleo de girassol', 'fr': "Huile de tournesol", 'de': 'Sonnenblumenöl', 'it': 'Olio di girasole', 'zh': '葵花籽油', 'hi': 'सूरजमुखी तेल', 'ar': 'زيت عباد الشمس', 'ru': 'Подсолнечное масло'},
    'Girassol Oil': {'es': 'Aceite de girasol', 'en': 'Sunflower oil', 'pt': 'Óleo de girassol', 'fr': "Huile de tournesol", 'de': 'Sonnenblumenöl', 'it': 'Olio di girasole', 'zh': '葵花籽油', 'hi': 'सूरजमुखी तेल', 'ar': 'زيت عباد الشمس', 'ru': 'Подсолнечное масло'},
    'Bacon': {'es': 'Tocino', 'en': 'Bacon', 'pt': 'Bacon', 'fr': 'Bacon', 'de': 'Speck', 'it': 'Pancetta', 'zh': '培根', 'hi': 'बेकन', 'ar': 'لحم مقدد', 'ru': 'Бекон'},
    'Chorizo': {'es': 'Chorizo', 'en': 'Chorizo', 'pt': 'Chouriço', 'fr': 'Chorizo', 'de': 'Chorizo', 'it': 'Salsiccia', 'zh': '香肠', 'hi': 'चोरिज़ो', 'ar': 'شوريزو', 'ru': 'Чоризо'},
    'Ham': {'es': 'Jamón', 'en': 'Ham', 'pt': 'Presunto', 'fr': 'Jambon', 'de': 'Schinken', 'it': 'Prosciutto', 'zh': '火腿', 'hi': 'हैम', 'ar': 'لحم مقدد', 'ru': 'Ветчина'},
    'Hot dog': {'es': 'Salchicha', 'en': 'Hot dog', 'pt': 'Cachorro-quente', 'fr': 'Hot-dog', 'de': 'Hotdog', 'it': 'Hot dog', 'zh': '热狗', 'hi': 'हॉट डॉग', 'ar': 'هوت دوغ', 'ru': 'Хот-дог'},
    'Shrimp': {'es': 'Camarones', 'en': 'Shrimp', 'pt': 'Camarão', 'fr': 'Crevettes', 'de': 'Garnelen', 'it': 'Gamberi', 'zh': '虾', 'hi': 'झींगा', 'ar': 'جمبري', 'ru': 'Креветки'},
    'Blueberry': {'es': 'Arándano', 'en': 'Blueberry', 'pt': 'Mirtilo', 'fr': 'Myrtille', 'de': 'Blaubeere', 'it': 'Mirtillo', 'zh': '蓝莓', 'hi': 'ब्लूबेरी', 'ar': 'توت أزرق', 'ru': 'Черника'},
    'Kiwi': {'es': 'Kiwi', 'en': 'Kiwi', 'pt': 'Kiwi', 'fr': 'Kiwi', 'de': 'Kiwi', 'it': 'Kiwi', 'zh': '猕猴桃', 'hi': 'कीवी', 'ar': 'كيوي', 'ru': 'Киви'},
    'Mandarin': {'es': 'Mandarina', 'en': 'Mandarin', 'pt': 'Tangerina', 'fr': 'Mandarine', 'de': 'Mandarine', 'it': 'Mandarino', 'zh': '橘子', 'hi': 'संतरा', 'ar': 'يوسفي', 'ru': 'Мандарин'},
    'Peach': {'es': 'Durazno', 'en': 'Peach', 'pt': 'Pêssego', 'fr': 'Pêche', 'de': 'Pfirsich', 'it': 'Pesca', 'zh': '桃子', 'hi': 'आड़ू', 'ar': 'خوخ', 'ru': 'Персик'},
    'Pear': {'es': 'Pera', 'en': 'Pear', 'pt': 'Pera', 'fr': 'Poire', 'de': 'Birne', 'it': 'Pera', 'zh': '梨', 'hi': 'नाशपाती', 'ar': 'كمثرى', 'ru': 'Груша'},
    'Raspberry': {'es': 'Frambuesa', 'en': 'Raspberry', 'pt': 'Framboesa', 'fr': 'Framboise', 'de': 'Himbeere', 'it': 'Lampone', 'zh': '树莓', 'hi': 'रसभरी', 'ar': 'توت العليق', 'ru': 'Малина'},
    'Cherry tomato': {'es': 'Tomate cherry', 'en': 'Cherry tomato', 'pt': 'Tomate cereja', 'fr': 'Tomate cerise', 'de': 'Kirschtomate', 'it': 'Pomodoro ciliegino', 'zh': '圣女果', 'hi': 'चेरी टमाटर', 'ar': 'طماطم كرزية', 'ru': 'Помидоры черри'},
    'Eggplant': {'es': 'Berenjena', 'en': 'Eggplant', 'pt': 'Beringela', 'fr': 'Aubergine', 'de': 'Aubergine', 'it': 'Melanzana', 'zh': '茄子', 'hi': 'बैंगन', 'ar': 'باذنجان', 'ru': 'Баклажан'},
    'Octopus': {'es': 'Pulpo', 'en': 'Octopus', 'pt': 'Polvo', 'fr': 'Poulpe', 'de': 'Oktopus', 'it': 'Polpo', 'zh': '章鱼', 'hi': 'ऑक्टोपस', 'ar': 'أخطبوط', 'ru': 'Осьминог'},
    'Softener': {'es': 'Suavizante', 'en': 'Fabric softener', 'pt': 'Amaciante', 'fr': 'Assouplissant', 'de': 'Weichspüler', 'it': 'Ammorbidente', 'zh': '柔顺剂', 'hi': 'सॉफ़्टनर', 'ar': 'منعم الملابس', 'ru': 'Кондиционер для белья'},
    'Scouring pad': {'es': 'Estropajo', 'en': 'Scouring pad', 'pt': 'Esponja de aço', 'fr': 'Tampon à récurer', 'de': 'Scheuerschwamm', 'it': 'Paglietta', 'zh': '钢丝球', 'hi': 'सफ़ाई पैड', 'ar': 'ليفة معدنية', 'ru': 'Жёсткая губка'},
    'Dish washer': {'es': 'Lavavajillas', 'en': 'Dishwasher', 'pt': 'Máquina de lavar louça', 'fr': 'Lave-vaisselle', 'de': 'Geschirrspüler', 'it': 'Lavastoviglie', 'zh': '洗碗机', 'hi': 'डिशवॉशर', 'ar': 'غسالة أطباق', 'ru': 'Посудомоечная машина'},
    'Dish sponge': {'es': 'Esponja de cocina', 'en': 'Dish sponge', 'pt': 'Esponja de cozinha', 'fr': 'Éponge à vaisselle', 'de': 'Spülschwamm', 'it': 'Spugnetta', 'zh': '洗碗海绵', 'hi': 'बर्तन स्पंज', 'ar': 'إسفنجة أطباق', 'ru': 'Губка для посуды'},
    'White beans': {'es': 'Alubias blancas', 'en': 'White beans', 'pt': 'Feijão branco', 'fr': 'Haricots blancs', 'de': 'Weiße Bohnen', 'it': 'Fagioli bianchi', 'zh': '白豆', 'hi': 'सफ़ेद बीन्स', 'ar': 'فاصولياء بيضاء', 'ru': 'Белая фасоль'},
    'Red beans': {'es': 'Alubias rojas', 'en': 'Red beans', 'pt': 'Feijão vermelho', 'fr': 'Haricots rouges', 'de': 'Rote Bohnen', 'it': 'Fagioli rossi', 'zh': '红豆', 'hi': 'लाल बीन्स', 'ar': 'فاصولياء حمراء', 'ru': 'Красная фасоль'},
    'Black-eyed beans': {'es': 'Frijoles de carita', 'en': 'Black-eyed beans', 'pt': 'Feijão-fradinho', 'fr': 'Cornilles', 'de': 'Augenbohnen', 'it': 'Fagioli dall\'occhio', 'zh': '黑眼豆', 'hi': 'काली आँखों वाली बीन्स', 'ar': 'لوبياء سوداء العين', 'ru': 'Коровий горох'},
    'Green banana': {'es': 'Plátano verde', 'en': 'Green banana', 'pt': 'Banana verde', 'fr': 'Banane verte', 'de': 'Grüne Banane', 'it': 'Banana verde', 'zh': '青蕉', 'hi': 'हरा केला', 'ar': 'موز أخضر', 'ru': 'Зелёный банан'},
    'Lime': {'es': 'Lima', 'en': 'Lime', 'pt': 'Lima', 'fr': 'Citron vert', 'de': 'Limette', 'it': 'Lime', 'zh': '青柠', 'hi': 'नींबू', 'ar': 'ليمون أخضر', 'ru': 'Лайм'},
    'Lentils': {'es': 'Lentejas', 'en': 'Lentils', 'pt': 'Lentilhas', 'fr': 'Lentilles', 'de': 'Linsen', 'it': 'Lenticchie', 'zh': '扁豆', 'hi': 'दाल', 'ar': 'عدس', 'ru': 'Чечевица'},
    'Powder coffee': {'es': 'Café soluble', 'en': 'Instant coffee', 'pt': 'Café solúvel', 'fr': 'Café soluble', 'de': 'Löslicher Kaffee', 'it': 'Caffè solubile', 'zh': '速溶咖啡', 'hi': 'इंस्टेंट कॉफ़ी', 'ar': 'قهوة فورية', 'ru': 'Растворимый кофе'},
    'Powder chocolate': {'es': 'Chocolate en polvo', 'en': 'Powdered chocolate', 'pt': 'Chocolate em pó', 'fr': 'Chocolat en poudre', 'de': 'Kakaopulver', 'it': 'Cioccolato in polvere', 'zh': '巧克力粉', 'hi': 'चॉकलेट पाउडर', 'ar': 'مسحوق الشوكولاتة', 'ru': 'Какао-порошок'},
    'Barley powder': {'es': 'Polvo de cebada', 'en': 'Barley powder', 'pt': 'Pó de cevada', 'fr': "Poudre d'orge", 'de': 'Gerstenpulver', 'it': "Polvere d'orzo", 'zh': '大麦粉', 'hi': 'जौ पाउडर', 'ar': 'مسحوق الشعير', 'ru': 'Ячменный порошок'},
    'Orange juice': {'es': 'Jugo de naranja', 'en': 'Orange juice', 'pt': 'Suco de laranja', 'fr': "Jus d'orange", 'de': 'Orangensaft', 'it': "Succo d'arancia", 'zh': '橙汁', 'hi': 'संतरे का जूस', 'ar': 'عصير برتقال', 'ru': 'Апельсиновый сок'},
    'Mango juice': {'es': 'Jugo de mango', 'en': 'Mango juice', 'pt': 'Suco de manga', 'fr': 'Jus de mangue', 'de': 'Mangosaft', 'it': 'Succo di mango', 'zh': '芒果汁', 'hi': 'आम का जूस', 'ar': 'عصير مانجو', 'ru': 'Манговый сок'},
    'Apple juice': {'es': 'Jugo de manzana', 'en': 'Apple juice', 'pt': 'Suco de maçã', 'fr': 'Jus de pomme', 'de': 'Apfelsaft', 'it': 'Succo di mela', 'zh': '苹果汁', 'hi': 'सेब का जूस', 'ar': 'عصير تفاح', 'ru': 'Яблочный сок'},
    'Pear juice': {'es': 'Jugo de pera', 'en': 'Pear juice', 'pt': 'Suco de pera', 'fr': 'Jus de poire', 'de': 'Birnensaft', 'it': 'Succo di pera', 'zh': '梨汁', 'hi': 'नाशपाती का जूस', 'ar': 'عصير كمثرى', 'ru': 'Грушевый сок'},
    'Peach juice': {'es': 'Jugo de durazno', 'en': 'Peach juice', 'pt': 'Suco de pêssego', 'fr': 'Jus de pêche', 'de': 'Pfirsichsaft', 'it': 'Succo di pesca', 'zh': '桃汁', 'hi': 'आड़ू का जूस', 'ar': 'عصير خوخ', 'ru': 'Персиковый сок'},
    'Pineapple juice': {'es': 'Jugo de piña', 'en': 'Pineapple juice', 'pt': 'Suco de abacaxi', 'fr': "Jus d'ananas", 'de': 'Ananassaft', 'it': "Succo d'ananas", 'zh': '菠萝汁', 'hi': 'अनानास का जूस', 'ar': 'عصير أناناس', 'ru': 'Ананасовый сок'},
    'Strawberry juice': {'es': 'Jugo de fresa', 'en': 'Strawberry juice', 'pt': 'Suco de morango', 'fr': 'Jus de fraise', 'de': 'Erdbeersaft', 'it': 'Succo di fragola', 'zh': '草莓汁', 'hi': 'स्ट्रॉबेरी का जूस', 'ar': 'عصير فراولة', 'ru': 'Клубничный сок'},
    'Guava juice': {'es': 'Jugo de guayaba', 'en': 'Guava juice', 'pt': 'Suco de goiaba', 'fr': 'Jus de goyave', 'de': 'Guavensaft', 'it': 'Succo di guava', 'zh': '番石榴汁', 'hi': 'अमरूद का जूस', 'ar': 'عصير جوافة', 'ru': 'Гуавовый сок'},
    'Beer': {'es': 'Cerveza', 'en': 'Beer', 'pt': 'Cerveja', 'fr': 'Bière', 'de': 'Bier', 'it': 'Birra', 'zh': '啤酒', 'hi': 'बीयर', 'ar': 'بيرة', 'ru': 'Пиво'},
    'Bottle beer': {'es': 'Cerveza de botella', 'en': 'Bottle beer', 'pt': 'Cerveja de garrafa', 'fr': 'Bière en bouteille', 'de': 'Flaschenbier', 'it': 'Birra in bottiglia', 'zh': '瓶装啤酒', 'hi': 'बोतल बीयर', 'ar': 'بيرة في زجاجة', 'ru': 'Бутылочное пиво'},
    'Red wine': {'es': 'Vino tinto', 'en': 'Red wine', 'pt': 'Vinho tinto', 'fr': 'Vin rouge', 'de': 'Rotwein', 'it': 'Vino rosso', 'zh': '红葡萄酒', 'hi': 'रेड वाइन', 'ar': 'نبيذ أحمر', 'ru': 'Красное вино'},
    'White wine': {'es': 'Vino blanco', 'en': 'White wine', 'pt': 'Vinho branco', 'fr': 'Vin blanc', 'de': 'Weißwein', 'it': 'Vino bianco', 'zh': '白葡萄酒', 'hi': 'व्हाइट वाइन', 'ar': 'نبيذ أبيض', 'ru': 'Белое вино'},
    'Conditioner': {'es': 'Acondicionador', 'en': 'Conditioner', 'pt': 'Condicionador', 'fr': 'Après-shampooing', 'de': 'Spülung', 'it': 'Balsamo', 'zh': '护发素', 'hi': 'कंडीशनर', 'ar': 'بلسم الشعر', 'ru': 'Кондиционер для волос'},
    'Bath gel': {'es': 'Gel de baño', 'en': 'Bath gel', 'pt': 'Gel de banho', 'fr': 'Gel douche', 'de': 'Duschgel', 'it': 'Bagnoschiuma', 'zh': '沐浴露', 'hi': 'बाथ जेल', 'ar': 'جل الاستحمام', 'ru': 'Гель для душа'},
    'Baby wipes': {'es': 'Toallitas húmedas', 'en': 'Baby wipes', 'pt': 'Toalhetes', 'fr': 'Lingettes', 'de': 'Feuchttücher', 'it': 'Salviettine', 'zh': '婴儿湿巾', 'hi': 'बेबी वाइप्स', 'ar': 'مناديل مبللة', 'ru': 'Влажные салфетки'},
    'Baby diapers': {'es': 'Pañales', 'en': 'Baby diapers', 'pt': 'Fraldas', 'fr': 'Couches', 'de': 'Windeln', 'it': 'Pannolini', 'zh': '婴儿纸尿裤', 'hi': 'बेबी डायपर', 'ar': 'حفاضات للأطفال', 'ru': 'Подгузники'},
    'Sausage': {'es': 'Salchicha', 'en': 'Sausage', 'pt': 'Salsicha', 'fr': 'Saucisse', 'de': 'Wurst', 'it': 'Salsiccia', 'zh': '香肠', 'hi': 'सॉसेज', 'ar': 'سجق', 'ru': 'Колбаса'},
  };

  String getName(String key) {
    final direct = _names[key]?[langCode];
    if (direct != null) return direct;
    // Clave guardada con formato libre ("Leche", "tomates", otra lengua...):
    // resolver contra el diccionario antes de mostrar el texto crudo.
    final resolvedKey = findNameKey(key);
    if (resolvedKey != null) return _names[resolvedKey]![langCode]!;
    return key;
  }

  String getCategoryName(String key) => getName(key);

  String getProductName(String key) => getName(key);

  static String? findNameKey(String text) {
    final normalizedInput = _normalize(text);
    if (normalizedInput.isEmpty) return null;

    // Tolerancia a plurales: "Tomates" -> "tomate", "Panes" -> "pan".
    final candidates = <String>[normalizedInput];
    if (normalizedInput.endsWith('es') && normalizedInput.length > 4) {
      candidates.add(normalizedInput.substring(0, normalizedInput.length - 2));
    }
    if (normalizedInput.endsWith('s') && normalizedInput.length > 3) {
      candidates.add(normalizedInput.substring(0, normalizedInput.length - 1));
    }

    final normalizedValues = <String, String>{
      for (final entry in _names.entries)
        for (final value in entry.value.values) _normalize(value): entry.key,
    };
    for (final candidate in candidates) {
      final resolved = normalizedValues[candidate];
      if (resolved != null) return resolved;
    }
    return null;
  }

  String get buyTitle => _s('buyTitle');
  String get stockTitle => _s('stockTitle');
  String get navBuy => _s('navBuy');
  String get navStock => _s('navStock');
  String get settings => _s('settings');
  String get darkMode => _s('darkMode');
  String get categoryView => _s('categoryView');
  String get categoryLabel => _s('categoryLabel');
  String get list => _s('list');
  String get gallery => _s('gallery');
  String get language => _s('language');
  String get addCategory => _s('addCategory');
  String get categoryAlreadyExists => _s('categoryAlreadyExists');
  String get newProduct => _s('newProduct');
  String get editCategory => _s('editCategory');
  String get deleteCategory => _s('deleteCategory');
  String get cancel => _s('cancel');
  String get save => _s('save');
  String get add => _s('add');
  String get delete => _s('delete');
  String get edit => _s('edit');
  String get productsCount => _s('productsCount');
  String get noCategories => _s('noCategories');
  String get emptyCategoriesSubtitle => _s('emptyCategoriesSubtitle');
  String get noProducts => _s('noProducts');
  String get emptyProductsSubtitle => _s('emptyProductsSubtitle');
  String get about => _s('about');
  String get version => _s('version');
  String get nameLabel => _s('nameLabel');
  String get exampleProductHint => _s('exampleProductHint');
  String get exampleCategoryHint => _s('exampleCategoryHint');
  String get visualCustomization => _s('visualCustomization');
  String get camera => _s('camera');
  String get galleryPicker => _s('galleryPicker');
  String get shareList => _s('shareList');
  String get shareListSub => _s('shareListSub');
  String get exportList => _s('exportList');
  String get exportListTitle => _s('exportListTitle');
  String get exportAsPdf => _s('exportAsPdf');
  String get exportAsImage => _s('exportAsImage');
  String get exportListEmpty => _s('exportListEmpty');
  String get exporting => _s('exporting');
  String get exportFailed => _s('exportFailed');
  String get shoppingList => _s('shoppingList');
  String get subcategory => _s('subcategory');
  String get subcategories => _s('subcategories');
  String get noSubcategory => _s('noSubcategory');
  String get newSubcategory => _s('newSubcategory');
  String get subcategoryHint => _s('subcategoryHint');
  String get renameSubcategory => _s('renameSubcategory');
  String get deleteSubcategory => _s('deleteSubcategory');
  String deleteSubcategoryConfirm(String name) =>
      _s('deleteSubcategoryConfirm').replaceFirst('{name}', name);

  String subcategoryCreated(String name) =>
      _s('subcategoryCreated').replaceFirst('{name}', name);
  String get moveProduct => _s('moveProduct');
  String movedProductTo(String sub) =>
      _s('movedProductTo').replaceFirst('{sub}', sub);
  String get moveToCategory => _s('moveToCategory');
  String get select => _s('select');
  String get move => _s('move');
  String selectedCount(int count) =>
      _s('selectedCount').replaceFirst('{count}', '$count');
  String movedProductsTo(int count, String sub) => _s('movedProductsTo')
      .replaceFirst('{count}', '$count')
      .replaceFirst('{sub}', sub);
  String get managePermissions => _s('managePermissions');
  String get managePermissionsSub => _s('managePermissionsSub');
  String get signOut => _s('signOut');
  String get manageCollaborators => _s('manageCollaborators');
  String get notAuthenticated => _s('notAuthenticated');
  String get noCollaborators => _s('noCollaborators');
  String get permissionPrefix => _s('permissionPrefix');
  String get permissionLabel => _s('permissionLabel');
  String get roleFull => _s('roleFull');
  String get roleDynamic => _s('roleDynamic');
  String get roleRead => _s('roleRead');
  String get roleUnknown => _s('roleUnknown');
  String get addCollaborator => _s('addCollaborator');
  String get collaboratorsUsed => _s('collaboratorsUsed');
  String get collaboratorsPremiumPlusLimit =>
      _s('collaboratorsPremiumPlusLimit');
  String get collaboratorPrompt => _s('collaboratorPrompt');
  String get emailLabel => _s('emailLabel');
  String get savedSuccessfully => _s('savedSuccessfully');
  String get errorSaving => _s('errorSaving');
  String get unexpectedError => _s('unexpectedError');
  String get authTabLogin => _s('authTabLogin');
  String get authTabRegister => _s('authTabRegister');
  String get authTagline => _s('authTagline');
  String get authPasswordLabel => _s('authPasswordLabel');
  String get authPasswordHintRegister => _s('authPasswordHintRegister');
  String get authLoginButton => _s('authLoginButton');
  String get authRegisterButton => _s('authRegisterButton');
  String get authOrContinue => _s('authOrContinue');
  String get authGoogleButton => _s('authGoogleButton');
  String get authRequiredField => _s('authRequiredField');
  String get errorInvalidEmail => _s('errorInvalidEmail');
  String get errorWrongPassword => _s('errorWrongPassword');
  String get errorUserNotFound => _s('errorUserNotFound');
  String get errorEmailInUse => _s('errorEmailInUse');
  String get errorWeakPassword => _s('errorWeakPassword');
  String get errorNetwork => _s('errorNetwork');
  String get errorGenericAuth => _s('errorGenericAuth');
  String get authTermsNote => _s('authTermsNote');
  String get selectLanguage => _s('selectLanguage');
  String get appName => _s('appName');
  String get loading => _s('loading');
  String get ownerPrefix => _s('ownerPrefix');
  String get collaboratorOf => _s('collaboratorOf');
  String get emailShort => _s('emailShort');
  String get premiumTitle => _s('premiumTitle');
  String get premiumBenefit1 => _s('premiumBenefit1');
  String get premiumBenefit2 => _s('premiumBenefit2');
  String get premiumBenefit3 => _s('premiumBenefit3');
  String get premiumPriceFallback => _s('premiumPriceFallback');
  String get premiumRestore => _s('premiumRestore');
  String get premiumActive => _s('premiumActive');
  String get premiumLimitCategories => _s('premiumLimitCategories');
  String get premiumLimitProducts => _s('premiumLimitProducts');
  String get purchaseSuccess => _s('purchaseSuccess');
  String get purchaseError => _s('purchaseError');
  String get purchasePending => _s('purchasePending');
  String get premiumBenefitCollaborators => _s('premiumBenefitCollaborators');
  String get premiumBenefitDarkMode => _s('premiumBenefitDarkMode');
  String get premiumBenefitGalleryView => _s('premiumBenefitGalleryView');
  String get premiumLimitCollaborators => _s('premiumLimitCollaborators');
  String get premiumFeatureExclusive => _s('premiumFeatureExclusive');
  String get plusTitle => _s('plusTitle');
  String get plusPriceFallback => _s('plusPriceFallback');
  String get plusActive => _s('plusActive');
  String get plusBenefitExport => _s('plusBenefitExport');
  String get plusBenefitSubcategories => _s('plusBenefitSubcategories');
  String get plusBenefitNotifications => _s('plusBenefitNotifications');
  String get plusBenefitSuggestions => _s('plusBenefitSuggestions');
  String get plusBenefitCollaborators => _s('plusBenefitCollaborators');
  String get plusExclusive => _s('plusExclusive');
  String get quantityLabel => _s('quantityLabel');
  String get unitLabel => _s('unitLabel');
  String get forgotPassword => _s('forgotPassword');
  String get resetPasswordTitle => _s('resetPasswordTitle');
  String get resetPasswordSubtitle => _s('resetPasswordSubtitle');
  String get resetPasswordButton => _s('resetPasswordButton');
  String get resetPasswordSuccess => _s('resetPasswordSuccess');

  String unlockFor(String price) =>
      interpolate('unlockFor', {'price': price});

  String unlockPlusFor(String price) =>
      interpolate('unlockPlusFor', {'price': price});

  String collaboratorsUsedText(int used, int max) => interpolate(
      'collaboratorsUsed',
      {'used': '$used', 'max': '$max'},
    );

  String deleteProductConfirm(String name) =>
      interpolate('deleteProductConfirm', {'name': name});
  String deleteCategoryConfirm(String name) =>
      interpolate('deleteCategoryConfirm', {'name': name});
  String removeCollaboratorConfirm(String name) =>
      interpolate('removeCollaboratorConfirm', {'name': name});

  String get collaboratorRemoved => _s('collaboratorRemoved');
  String get permissionDenied => _s('permissionDenied');

  String get notifications => _s('notifications');
  String get notificationCenterEmpty => _s('notificationCenterEmpty');
  String get markAllRead => _s('markAllRead');
  String get shoppingReminderTitle => _s('shoppingReminderTitle');
  String shoppingReminderBody(String items) =>
      interpolate('shoppingReminderBody', {'items': items});
  String get suggestedProductsTitle => _s('suggestedProductsTitle');
  String get suggestedProductsSubtitle => _s('suggestedProductsSubtitle');
  String get addSuggestedToList => _s('addSuggestedToList');
  String get suggestionsAddedSuccess => _s('suggestionsAddedSuccess');
  String get noActiveSuggestion => _s('noActiveSuggestion');
  String get notificationsRequirePlus => _s('notificationsRequirePlus');
  String get suggestionAddMoreItems => _s('suggestionAddMoreItems');
  String get suggestionSearchHint => _s('suggestionSearchHint');
  String get suggestionEdit => _s('suggestionEdit');
  String get suggestionEditHint => _s('suggestionEditHint');
  String get suggestionQuantityEmpty => _s('suggestionQuantityEmpty');
  String get suggestionNoResults => _s('suggestionNoResults');
  String get all => _s('all');
}
