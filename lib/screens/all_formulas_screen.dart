import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/widgets/adaptive_scaffold.dart';
import 'package:mnemonicorum/widgets/optimized_formula_list.dart';

class AllFormulasScreen extends StatefulWidget {
  const AllFormulasScreen({super.key});

  @override
  State<AllFormulasScreen> createState() => _AllFormulasScreenState();
}

class _AllFormulasScreenState extends State<AllFormulasScreen> {
  late Future<List<Formula>> _allFormulasFuture;
  List<Formula> _filteredFormulas = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  Set<String?> _selectedSubcategory = {null}; // For SegmentedButton

  @override
  void initState() {
    super.initState();
    _allFormulasFuture = _loadAllFormulas();
    _searchController.addListener(() {
      _filterFormulas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Formula>> _loadAllFormulas() async {
    final formulaRepository = Provider.of<FormulaRepository>(
      context,
      listen: false,
    );
    // Ensure all formulas from all categories are loaded for this screen
    await Future.wait(
      formulaRepository.getAllCategories().map(
        (cat) => formulaRepository.getFormulasByCategory(cat.id),
      ),
    );
    final formulas = formulaRepository.getAllFormulasNow();
    if (mounted) {
      setState(() {
        _filteredFormulas = formulas;
      });
    }
    return formulas;
  }

  void _filterFormulas() {
    final allFormulas = Provider.of<FormulaRepository>(
      context,
      listen: false,
    ).getAllFormulasNow();
    final searchQuery = _searchController.text.toLowerCase();
    final subcategory = _selectedSubcategory.first;

    setState(() {
      _filteredFormulas = allFormulas.where((formula) {
        final matchesSearchQuery =
            searchQuery.isEmpty ||
            formula.name.toLowerCase().contains(searchQuery) ||
            formula.description.toLowerCase().contains(searchQuery) ||
            formula.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
        final matchesCategory =
            _selectedCategory == null || formula.category == _selectedCategory;
        final matchesSubcategory =
            subcategory == null || formula.subcategory == subcategory;
        return matchesSearchQuery && matchesCategory && matchesSubcategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentRoute: '/all-formulas',
      title: '所有公式',
      body: FutureBuilder<List<Formula>>(
        future: _allFormulasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载公式失败: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有可用的公式。'));
          }

          final allFormulas = snapshot.data!;
          final categories = allFormulas
              .map((f) => f.category)
              .toSet()
              .toList();
          final subcategories = allFormulas
              .map((f) => f.subcategory)
              .toSet()
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: '搜索公式名称、描述或标签...',
                  leading: const Icon(Icons.search),
                  onChanged: (value) => _filterFormulas(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    DropdownMenu<String?>(
                      initialSelection: null,
                      hintText: '选择类别',
                      onSelected: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _filterFormulas();
                        });
                      },
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: null, label: '所有类别'),
                        ...categories.map(
                          (c) => DropdownMenuEntry(value: c, label: c),
                        ),
                      ],
                    ),
                    if (subcategories.isNotEmpty)
                      SegmentedButton<String?>(
                        segments: [
                          const ButtonSegment(
                            value: null,
                            label: Text('所有子类别'),
                          ),
                          ...subcategories.map(
                            (s) => ButtonSegment(value: s, label: Text(s)),
                          ),
                        ],
                        selected: _selectedSubcategory,
                        onSelectionChanged: (Set<String?> newSelection) {
                          setState(() {
                            _selectedSubcategory = newSelection;
                            _filterFormulas();
                          });
                        },
                        showSelectedIcon: false,
                        multiSelectionEnabled: false,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: OptimizedFormulaList(
                  formulas: _filteredFormulas,
                  onFormulaTap: (formula) {
                    // Navigate to a formula detail screen if you have one
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
