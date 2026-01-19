import 'package:flutter/material.dart';
import 'goal_list.dart';
import 'new_list_view.dart';
import 'file_manager.dart';
import 'input_area.dart';
import 'scrollable_tabs.dart';

/// Kobler sammen alle darts filene, og husker tilstanden til
/// appen
class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

/// State for MainView
class _MainViewState extends State<MainView> {
  // Index på aktiv liste
  int selectedTabIndex = 0;

  // Controller for scroll av tabs (valg av liste)
  final ScrollController _scrollController = ScrollController();

  // Liste over navn til lister
  List<String> tabTitles = [];

  // Alle items, for hver liste
  late List<List<String>> _items;

  // Status for hver item (ferdig /ikke ferdig), for hver liste
  late List<List<bool>> _finishedStates;

  // Scrollcontrollers for ferdige items
  late List<ScrollController> _finishedItemsControllers;

  // Scrollcontrollers for uferdige items
  late List<ScrollController> _unfinishedItemsControllers;

  // Controller for tekstfelt
  final TextEditingController _textController = TextEditingController();

  // Holder referanse til sjekkliste-tilstander
  final Map<int, GoalListState> _checkListStates = {};

  // Offset når i landskap-modus
  final double _landscapeOffset = 10;

  // Feilmelding for tekstfelt
  String? _itemErrorText;

  // Fokusnode for tekstfelt (ettersom tastatur skal vises ved fokus
  // opp mot tekstfelt)
  final FocusNode _focusNode = FocusNode();

  // Om tekstfeltet er i fokus
  bool _textFieldInFocus = false;

  @override
  ///Setter opp start tilstand
  void initState() {
    super.initState();
    _initializeLists();
    _loadAllListsFromFiles();

    // Sjekker om tekstfeltet er i fokus
    _focusNode.addListener(() {
      setState(() {
        _textFieldInFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    for (final controller in _finishedItemsControllers) {
      controller.dispose();
    }
    for (final controller in _unfinishedItemsControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Initialiserer tomme lister for alle tabs (lister en kan velge)
  void _initializeLists() {
    _items = List.generate(tabTitles.length, (_) => <String>[], growable: true);
    _finishedStates = List.generate(tabTitles.length, (_) => <bool>[], growable: true);
    _finishedItemsControllers = List.generate(tabTitles.length, (_) => ScrollController());
    _unfinishedItemsControllers = List.generate(tabTitles.length, (_) => ScrollController());
  }

  /// Leser inn alle lagrede sjekklister fra filer
  Future<void> _loadAllListsFromFiles() async {
    final data = await FileManager.loadAllLists();

    setState(() {
      tabTitles = List<String>.from(data['listNames'] as List);
      _items = List<List<String>>.from(data['itemsList'] as List);
      _finishedStates = List<List<bool>>.from(data['finishedList'] as List);
      _finishedItemsControllers = List.generate(tabTitles.length, (_) => ScrollController());
      _unfinishedItemsControllers = List.generate(tabTitles.length, (_) => ScrollController());

      if (tabTitles.isEmpty) _initializeLists();
      if (selectedTabIndex >= tabTitles.length) {
        selectedTabIndex = tabTitles.isEmpty ? 0 : tabTitles.length - 1;
      }
    });
  }

  /// Legger til nytt item i aktiv liste
  void _addNewItem() {
    if (tabTitles.isEmpty) return;
    final text = _textController.text.trim();

    if (text.isEmpty || text.length > 5) {
      setState(() =>
      _itemErrorText = 'Navnet på målet må være mellom 1 og 5 tegn');
      return;
    }

    final checkListState = _checkListStates[selectedTabIndex];
    if (checkListState != null) {
      checkListState.addNewItem(text);
    } else {
      setState(() {
        _items[selectedTabIndex].add(text);
        _finishedStates[selectedTabIndex].add(false);
      });
    }

    FileManager.saveListByIndex(selectedTabIndex, tabTitles, _items, _finishedStates);
    _textController.clear();
    _focusNode.unfocus();
    _textFieldInFocus = false;
    _itemErrorText = null;
  }

  /// Åpner nytt "fragment" for å legge til ny liste
  void _addNewList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewList(
          onAddList: (text) {
            setState(() {
              tabTitles.add(text);
              _items.add([]);
              _finishedStates.add([]);
              _finishedItemsControllers.add(ScrollController());
              _unfinishedItemsControllers.add(ScrollController());
              selectedTabIndex = tabTitles.length - 1;
            });
            FileManager.createNewList(text);
          },
          listTitles: tabTitles,
        ),
      ),
    );
  }

  /// Fjerner aktiv fane og sletter tilhørende fil
  void _removeCurrentTab() {
    if (tabTitles.isEmpty) return;

    final listNameToDelete = tabTitles[selectedTabIndex];
    FileManager.deleteList(listNameToDelete);

    setState(() {
      final removedFinishedItem = _finishedItemsControllers.removeAt(selectedTabIndex);
      final removedUnfinishedItem = _unfinishedItemsControllers.removeAt(selectedTabIndex);
      removedFinishedItem.dispose();
      removedUnfinishedItem.dispose();

      tabTitles.removeAt(selectedTabIndex);
      _items.removeAt(selectedTabIndex);
      _finishedStates.removeAt(selectedTabIndex);
      _checkListStates.remove(selectedTabIndex);

      final updatedStates = <int, GoalListState>{};
      _checkListStates.forEach((key, value) {
        if (key < selectedTabIndex) updatedStates[key] = value;
        if (key > selectedTabIndex) updatedStates[key - 1] = value;
      });
      _checkListStates
        ..clear()
        ..addAll(updatedStates);

      if (selectedTabIndex >= tabTitles.length) selectedTabIndex = tabTitles.length - 1;
    });
  }

  /// Scroll tab til venstre
  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 100).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Scroll tab til høyre
  void _scrollRight() {
    final max = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;
    final current = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final target = (current + 100).clamp(0.0, max);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        //For å unngå pixel overflow (svart/gult bånd på skjermen) error
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFC8E6C9),
        appBar: AppBar(
          toolbarHeight: 40,
          title: const Text('Huskeliste app'),
          elevation: 0,
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            //Nødvendig i landskap for å se input felt, på grunn av
            //tastatur. Skjules kun når tekstfelt er i fokus
            if (!(isLandscape && _textFieldInFocus))
              ScrollableTabs(
                selectedIndex: selectedTabIndex,
                tabTitles: tabTitles,
                scrollController: _scrollController,
                onTabSelected: (index) => setState(() => selectedTabIndex = index),
                onRemoveCurrentTab: _removeCurrentTab,
                onScrollLeft: _scrollLeft,
                onScrollRight: _scrollRight,
              ),
            InputArea(
              onAddNewGoalBtnPressed: _addNewItem,
              onAddNewListBtnPressed: _addNewList,
              textController: _textController,
              focusNode: _focusNode,
              errorText: _itemErrorText,
              isLandscape: isLandscape,
              landscapeOffset: _landscapeOffset,
              onTextChanged: (_) {
                if (_itemErrorText != null) {
                  setState(() => _itemErrorText = null);
                }
              },
            ),
            Expanded(child: _constructActiveCheckList(isLandscape)),
          ],
        ),
      ),
    );
  }

  /// Konsturerer selve sjekklisten
  Widget _constructActiveCheckList(bool isLandscape) {
    if (tabTitles.isEmpty) {
      return const Center(
        child: Text(
          'Legg til en ny liste ved å trykke på knappen "Ny liste"',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    while (_items.length <= selectedTabIndex) {
      _items.add([]);
    }
    while (_finishedStates.length <= selectedTabIndex) {
      _finishedStates.add([]);
    }
    while (_finishedItemsControllers.length <= selectedTabIndex) {
      _finishedItemsControllers.add(ScrollController());
    }
    while (_unfinishedItemsControllers.length <= selectedTabIndex) {
      _unfinishedItemsControllers.add(ScrollController());
    }

    return GoalList(
      key: ValueKey('checklist_$selectedTabIndex'),
      finishedTitle: 'Fullført',
      unfinishedTitle: 'Ikke fullført',
      items: _items[selectedTabIndex],
      finished: _finishedStates[selectedTabIndex],
      isLandscape: isLandscape,
      finishedController: _finishedItemsControllers[selectedTabIndex],
      unfinishedController: _unfinishedItemsControllers[selectedTabIndex],
      onStateCreated: (state) => _checkListStates[selectedTabIndex] = state,
      onItemsChanged: (items, finishedStates) {
        setState(() {
          while (_items.length <= selectedTabIndex) {
            _items.add([]);
          }
          while (_finishedStates.length <= selectedTabIndex) {
            _finishedStates.add([]);
          }
          _items[selectedTabIndex] = List<String>.from(items);
          _finishedStates[selectedTabIndex] = List<bool>.from(finishedStates);
        });
        FileManager.saveListByIndex(selectedTabIndex, tabTitles, _items, _finishedStates);
      },
    );
  }
}