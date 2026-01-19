import 'package:flutter/material.dart';
import 'item.dart';
import 'title_box.dart';


abstract class GoalListState {
  /// Legger til ny item i listen
  void addNewItem(String text);
}

/// Viser en liste med ferdige og uferdige items
/// Støtter horisontal og vertikal visioning avhengig av 'isLandscape'
class GoalList extends StatefulWidget {
  // Tittel for ferdige items
  final String finishedTitle;

  // Tittel for uferdige items
  final String unfinishedTitle;

  // Listen med alle items
  final List<String> items;

  // Status for om hver item er ferdig eller ikke
  final List<bool> finished;

  // Angir om listen vises i landskapsmodus
  final bool isLandscape;

  // ScrollController for ferdige items
  final ScrollController finishedController;

  // ScrollController for uferdige items
  final ScrollController unfinishedController;

  // Callback som håndterer event når widgetens state er opprettet
  final Function(GoalListState) onStateCreated;

  // Callback som håndterer event når items eller deres ferdig-status endres
  final void Function(List<String> items, List<bool> selected)? onItemsChanged;

  // Callback som håndterer sletting av item
  final void Function(String itemText)? onItemDeleted;

  const GoalList({
    super.key,
    required this.finishedTitle,
    required this.unfinishedTitle,
    required this.items,
    required this.finished,
    required this.isLandscape,
    required this.finishedController,
    required this.unfinishedController,
    required this.onStateCreated,
    this.onItemsChanged,
    this.onItemDeleted,
  });

  @override
  State<GoalList> createState() => _GoalList();
}
/// En widget som viser en sjekkliste med ferdige og uferdige items
/// Støtter horisontal og vertikal visioning avhengig av 'isLandscape'
class _GoalList extends State<GoalList>
    with AutomaticKeepAliveClientMixin
    implements GoalListState {
  @override
  bool get wantKeepAlive => true;

  final double _itemHeight = 60;
  final double _landscapeXOffset = 23;

  int? _draggingIndexFinished;
  int? _targetOverIndexFinished;

  int? _draggingIndexUnfinished;
  int? _targetOverIndexUnfinished;

  bool canLeftPressFinished = false;
  bool canRightPressFinished = true;

  bool canLeftPressUnfinished = false;
  bool canRightPressUnfinished = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateCreated(this);
      _updateFinishedButtons();
      _updateUnfinishedButtons();
    });
    widget.finishedController.addListener(_updateFinishedButtons);
    widget.unfinishedController.addListener(_updateUnfinishedButtons);
  }

  @override
  void dispose() {
    widget.finishedController.removeListener(_updateFinishedButtons);
    widget.unfinishedController.removeListener(_updateUnfinishedButtons);
    super.dispose();
  }

  void _updateFinishedButtons() {
    if (!widget.finishedController.hasClients) return;
    setState(() {
      canLeftPressFinished = widget.finishedController.offset > 0;
      canRightPressFinished =
          widget.finishedController.offset < widget.finishedController.position.maxScrollExtent;
    });
  }

  void _updateUnfinishedButtons() {
    if (!widget.unfinishedController.hasClients) return;
    setState(() {
      canLeftPressUnfinished = widget.unfinishedController.offset > 0;
      canRightPressUnfinished =
          widget.unfinishedController.offset < widget.unfinishedController.position.maxScrollExtent;
    });
  }
  ///Brukt av horisontal liste (i landskap) for å scrolle til venstre
  void _scrollLeft(ScrollController controller, {double step = 100}) {
    final newOffset = (controller.offset - step)
        .clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  ///Brukt av horisontal liste (i landskap) for å scrolle til høyre
  void _scrollRight(ScrollController controller, {double step = 100}) {
    final newOffset = (controller.offset + step)
        .clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  ///Oppdater tilstand til en spesifik item, i listen over alle items
  void _toggleItem(int index) {
    setState(() {
      //Hvis item finnes
      if (index < widget.finished.length) {
        // Toggle ferdig-tilstand
        final newFinishedState = !widget.finished[index];

        // Hent item
        final item = widget.items[index];

        // Plasser på slutten av listen over alle items
        int insertIndex = widget.items.length-1;


        // Fjern fra gammel posisjon
        widget.items.removeAt(index);
        widget.finished.removeAt(index);

        // Sett inn på ny posisjon med ny ferdig-tilstand
        widget.items.insert(insertIndex, item);
        widget.finished.insert(insertIndex, newFinishedState);
      }
    });
    //Oppdaterer tilstand til item
    widget.onItemsChanged?.call(widget.items, widget.finished);
  }
  ///Fjerner item fra listen over alle items
  void _removeItem(int index) {
    setState(() {
      //Hvis item finnes
      if (index < widget.items.length && index < widget.finished.length) {


        widget.items.removeAt(index);
        widget.finished.removeAt(index);


      }
    });


    widget.onItemsChanged?.call(widget.items, widget.finished);
  }

  @override
  ///Legger til item i listen over alle items
  void addNewItem(String text) {
    setState(() {
      widget.items.add(text);
      //Legges til liste over ikke-ferdige items
      widget.finished.add(false);
    });
    //Oppdater tilstand til item
    widget.onItemsChanged?.call(widget.items, widget.finished);
  }

  /// Bytter plass på to elementer innenfor samme liste,
  /// hvor en opperer med index opp mot liste over alle items.
  /// Bruker relativ plassering (noe er over/under eller til høyre /venstre)
  /// til item med samme state, i liste over alle items, samt filtrering
  /// for å holde rede på ordning internt i de to listene
  void _moveWithinList(
      //Index til item som blir flyttet, i listen over alle items
      int fromIndex,
      //Index til target item, i listen over alle items
      int toIndex,
      //Hvilke liste en sender til
          {required bool fromFinishedList}) {

    setState(() {

      //Fjern item fra liste over alle items
      final item = widget.items.removeAt(fromIndex);
      final targetFinishedState = widget.finished.removeAt(fromIndex);

      int insertIndex = toIndex;

      //Sørger for at en plasserer før target item, og ikke etter
      if (toIndex > fromIndex) insertIndex = toIndex - 1;

      //Legg til item til liste over alle items
      widget.items.insert(insertIndex, item);
      widget.finished.insert(insertIndex, targetFinishedState);

      //Fordi en ikke lenger dragger
      _draggingIndexFinished = null;
      _targetOverIndexFinished = null;
      _draggingIndexUnfinished = null;
      _targetOverIndexUnfinished = null;
    });
    //Oppdatert tilstand til item
    widget.onItemsChanged?.call(widget.items, widget.finished);
  }

  /// Flytter et element fra en liste til den andre (ferdig/uferdig)
  /// .Bruker relativ plassering (noe er over/under eller til høyre /venstre)
  /// til item med samme state, i liste over alle items, samt filtrering
  /// for å holde rede på ordning internt i de to listene
  void _moveItemBetweenLists(
      //Index til item som flyttes, i liste over alle items
      int fromIndex,
      //Type liste en kommer fra
      bool isFromFinishedList,
      //Index til target (som drag item er plassert over)
      //, i listen over alle items
      int? targetIndex,
      //Type liste en sender til
      bool isToFinishedList,
      //Hvis plassert på slutten av andre listen, må en behandle
      //overføringen mellom listene anderledes
          {
        bool toEnd = false,
      }) {
    setState(() {
      // Item som skal flyttes
      final item = widget.items[fromIndex];

      //Posisjon item som skal flyttes vil få (-1 betyr at den plasseres på slutten)
      int insertIndex = -1;


      //Om en plasserer på slutten i andre listen,
      //eller om index en plasserer over ikke finnes (er null / skal ikke skje)
      if (toEnd || targetIndex == null) {
        // Index til siste item med denne tilstand, i liste over alle items
        final lastIndex = widget.finished.lastIndexWhere((finishedState) => finishedState == isToFinishedList);
        //Skal plasseres som siste item, dvs en index større enn den siste
        //Om ingen index finnes (f.eks fordi listen er tom), så settes den til første index
        insertIndex = lastIndex == -1 ? 0 : lastIndex + 1;


      } else {
        // Hent ut alle items med ønsket state (er i den andre listen)
        // Dette representerer index i listen over alle items.
        // En skal her flytte på element i listen over alle items.
        final targetIndices = widget.finished
            .asMap()
            .entries
            .where((finishedState) => finishedState.value == isToFinishedList)
            .map((finishedState) => finishedState.key)
            .toList();

        //Listen er tom (skal ikke skje)
        if (targetIndices.isEmpty) {
          insertIndex = widget.items.length;
        } else {
          //Hvis en plasserer noe som første element, risikerer en negativ index
          // (må da settes lik 0)
          final toIndex = targetIndex == -1 ? 1 : targetIndex;

          //Lik seg selv, eller index til første item med denne tilstand
          // (fordi den var opprinnelig -1, og
          // satt lik 0). Målet er å finne første element med denne tilstanden,
          // i listen over alle items (utover dette vil ikke index endre seg)
          insertIndex = targetIndices[toIndex];
        }
      }

      // Fjern denne item i listen en kommer fra
      widget.items.removeAt(fromIndex);
      widget.finished.removeAt(fromIndex);

      // Skal være før denne, og ikke etter
      // target item i andre liste
      // (der gapet er)
      if (fromIndex < insertIndex) {
        insertIndex--;
      }

      // Sett inn item ny posisjon med motsatt ferdig-tilstand
      widget.items.insert(insertIndex, item);
      widget.finished.insert(insertIndex, isToFinishedList);

      //Fordi en er ferdig å dragge
      _draggingIndexFinished = null;
      _targetOverIndexFinished = null;
      _draggingIndexUnfinished = null;
      _targetOverIndexUnfinished = null;
    });
    //Fortell item-widget at ferdig-tilstanden er oppdatert
    widget.onItemsChanged?.call(widget.items, widget.finished);
  }

  Widget _constructDragTargetHorizontal(
      int targetIndex,
      String text,
      bool isInFinishedList, {
        required int toIndex,
        required int numberOfItems,
        required bool isItemInFinishedList,
      }) {
    //Index til item som blir dragget
    int? draggingIndex = isItemInFinishedList ? _draggingIndexFinished : _draggingIndexUnfinished;
    //Index til item dragged element er over
    int? targetOverIndex = isItemInFinishedList ? _targetOverIndexFinished : _targetOverIndexUnfinished;

    ///Setter index til item som blir dragget
    void setDraggingIndex(int? index) {
      setState(() {
        //Hvis ferdig-tilstand
        if (isItemInFinishedList) {
          _draggingIndexFinished = index;
        } else {
          _draggingIndexUnfinished = index;
        }
      });
    }
    ///Setter index til item, hvor dragged item er dragged over
    void setOverTargetIndex(int? index) {
      setState(() {
        //Hvis ferdig-tilstand
        if (isItemInFinishedList) {
          _targetOverIndexFinished = index;
        } else {
          _targetOverIndexUnfinished = index;
        }
      });
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final fromIndex = details.data;
        if (fromIndex == targetIndex) return false;

        setOverTargetIndex(targetIndex);
        return true;
      },
      onLeave: (_) => setOverTargetIndex(null),
      onAcceptWithDetails: (details) {
        final fromIndex = details.data;
        final isFromFinished = widget.finished[fromIndex];

        // Hvis samme liste, bruk moveWithinList
        if (isFromFinished == isItemInFinishedList) {
          _moveWithinList(fromIndex, targetIndex, fromFinishedList: isItemInFinishedList);
        } else {
          // Hvis forskjellige lister, bruk moveItemBetweenLists
          _moveItemBetweenLists(fromIndex, isFromFinished, toIndex, isItemInFinishedList);
        }

        setDraggingIndex(null);
        setOverTargetIndex(null);
      },
      builder: (context, candidateData, rejectedData) {
        double offsetX = 0;
        if (targetOverIndex != null &&
            targetIndex >= targetOverIndex &&
            widget.isLandscape) {
          offsetX = 160 + 4;
        }

        return Padding(
          padding: EdgeInsets.only(left: toIndex == 0 ? 8 : 4, right: 4),
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(offsetX, 0),
                child: LongPressDraggable<int>(
                  data: targetIndex,

                  onDragStarted: () => setDraggingIndex(targetIndex),
                  onDraggableCanceled: (_, _) {
                    setState(() {
                      if (isItemInFinishedList) {
                        _draggingIndexFinished = null;
                        _targetOverIndexFinished = null;
                      } else {
                        _draggingIndexUnfinished = null;
                        _targetOverIndexUnfinished = null;
                      }
                    });
                  },
                  onDragEnd: (_) {
                    setState(() {
                      _draggingIndexFinished = null;
                      _targetOverIndexFinished = null;
                      _draggingIndexUnfinished = null;
                      _targetOverIndexUnfinished = null;
                    });
                  },
                  //Det som vises ved drag, nær musen, ved
                  //long press
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.5,
                      child: CheckListItem(
                        text: text,
                        isInFinishedList: isInFinishedList,
                        isBeingDragged: true,
                        onToggle: () => _toggleItem(targetIndex),
                        onRemove: () => _removeItem(targetIndex),
                      ),
                    ),
                  ),
                  //Item som blir dragget er en kopi. Dette er
                  //hva som vises der item var før. Når item blir
                  //dragget, så vises et usynlig objekt istedet.
                  childWhenDragging: Opacity(
                    opacity: draggingIndex == targetIndex ? 0.0 : 1.0,
                    child: CheckListItem(
                      text: text,
                      isInFinishedList: isInFinishedList,
                      onToggle: () => _toggleItem(targetIndex),
                      onRemove: () => _removeItem(targetIndex),
                    ),
                  ),
                  //Item som vises når den ikke blir dragged
                  child: CheckListItem(
                    text: text,
                    isInFinishedList: isInFinishedList,
                    onToggle: () => _toggleItem(targetIndex),
                    onRemove: () => _removeItem(targetIndex),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  ///Horisontal liste over dragable items. Kan ikke gjøres
  ///på samme måte som med vertikale lister, fordi en ikke her har vanlig
  ///form for liste (vertikal liste)
  Widget _constructHorizontalList(
      List<MapEntry<int, String>> itemList,
      ScrollController controller,
      bool canLeftPress,
      bool canRightPress,
      bool isItemInFinishedList,
      ) {
    bool isInFinishedList(int key) => key < widget.finished.length ? widget.finished[key] : false;

    return Row(
      children: [
        if (canLeftPress)
          IconButton(
            icon: const Icon(Icons.arrow_left),
            onPressed: () => _scrollLeft(controller, step: 160),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                //Består av items en kan dragge
                for (int idx = 0; idx < itemList.length; idx++)
                //Item en kan dragge
                  _constructDragTargetHorizontal(
                    itemList[idx].key,
                    itemList[idx].value,
                    isInFinishedList(itemList[idx].key),
                    toIndex: idx,
                    numberOfItems: itemList.length,
                    isItemInFinishedList: isItemInFinishedList,
                  ),
                //Med tilhørende DragTarget (sted en kan droppe)
                //Target er plassert i gapet, når en plasserer
                //noe over en item
                DragTarget<int>(
                  //Aksepterer alle, når noe er dragget over target
                  onWillAcceptWithDetails: (details) => true,
                  //Når droppet over target
                  onAcceptWithDetails: (details) {
                    final fromIndex = details.data;
                    //Akkurat her, så flytter en til slutten av listen
                    //om denne ikke blir håndtert en annen plass
                    //(en måte å håndtere edge-case på), når
                    //listen er tom eller en plasserer det på slutten
                    //av listen
                    _moveItemBetweenLists(
                      fromIndex,
                      widget.finished[fromIndex],
                      null,
                      isItemInFinishedList,
                      toEnd: true,
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    //Representerer et gap hvor dragTarget er plassert
                    return SizedBox(width: 160, height: _itemHeight);
                  },
                ),
              ],
            ),
          ),
        ),
        if (canRightPress)
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () => _scrollRight(controller, step: 160),
          ),
      ],
    );
  }

  Widget _constructVerticalList(
      List<MapEntry<int, String>> itemList,
      ScrollController controller,
      bool isTargetInFinishedList,
      ) {
    bool isInFinishedList(int key) => key < widget.finished.length ? widget.finished[key] : false;

    return DragTarget<int>(
      //Når en plasserer dragged item over en annnen item
      onWillAcceptWithDetails: (_) => true,
      //Når en dropper item
      onAcceptWithDetails: (details) {
        final fromIndex = details.data;
        _moveItemBetweenLists(fromIndex, widget.finished[fromIndex], null, isTargetInFinishedList, toEnd: true);
      },
      builder: (context, candidateData, rejectedData) {
        return ListView.builder(
          controller: controller,
          itemCount: itemList.length,
          //Liste har denne, som gjør det lettere enn det horisontale tilfellet
          //(bruker itembuilder fremfor for løkke).

          itemBuilder: (context, idx) {
            final index = itemList[idx].key;
            final text = itemList[idx].value;
            //Hver item i listen er har en dragTarget,og en dragable item.
            //blir laget i build (alle har en dragable item
            // laget av LongPressDraggable event, og en dragTarget)
            return DragTarget<int>(
              //Når item er dragget over en item
              onWillAcceptWithDetails: (details) {

                setState(() {
                  if (isTargetInFinishedList) {
                    _targetOverIndexFinished = idx;
                  } else {
                    _targetOverIndexUnfinished = idx;
                  }
                });
                return true;
              },
              //Når item ikke lenger er dragget over denne item
              onLeave: (_) => setState(() {
                if (isTargetInFinishedList) {
                  _targetOverIndexFinished = null;
                } else {
                  _targetOverIndexUnfinished = null;
                }
              }),
              //Når item blir droppet over en annen item
              onAcceptWithDetails: (details) {
                final fromIndex = details.data;
                final isFromFinishedList = widget.finished[fromIndex];

                //Hvis droppet i samme liste
                if (isFromFinishedList == isTargetInFinishedList) {
                  _moveWithinList(fromIndex, index, fromFinishedList: isTargetInFinishedList);
                }
                //Dropper i en annen liste
                else {
                  _moveItemBetweenLists(fromIndex, isFromFinishedList, idx, isTargetInFinishedList);
                }
              },
              builder: (context, candidateData, rejectedData) {
                double offsetY = 0;
                //Når en dragger over en item, så blir target og alt under dyttet nedover
                if ((isTargetInFinishedList ? _targetOverIndexFinished : _targetOverIndexUnfinished) != null &&
                    idx >= (isTargetInFinishedList ? _targetOverIndexFinished! : _targetOverIndexUnfinished!)) {
                  offsetY = _itemHeight + 4;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Transform.translate(
                    offset: Offset(0, offsetY),
                    child: LongPressDraggable<int>(
                      data: index,
                      onDragStarted: () {
                        setState(() {
                          if (isTargetInFinishedList) {
                            _draggingIndexFinished = index;
                          } else {
                            _draggingIndexUnfinished = index;
                          }
                        });
                      },
                      onDraggableCanceled: (_, _) {
                        setState(() {
                          _draggingIndexFinished = null;
                          _targetOverIndexFinished = null;
                          _draggingIndexUnfinished = null;
                          _targetOverIndexUnfinished = null;
                        });
                      },
                      onDragEnd: (_) {
                        setState(() {
                          _draggingIndexFinished = null;
                          _targetOverIndexFinished = null;
                          _draggingIndexUnfinished = null;
                          _targetOverIndexUnfinished = null;
                        });
                      },
                      //Item blir kopiert, så det som er i listen
                      //gjøres usynlig ved å shrinke boksen
                      // (gjøres så liten som mulig)
                      childWhenDragging: const SizedBox.shrink(),
                      //Det som følger med musepekeren (en spessial laget item)
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.8,
                          child: CheckListItem(
                            text: text,
                            isInFinishedList: isInFinishedList(index),
                            isBeingDragged: true,
                            width: MediaQuery.of(context).size.width * 0.9,
                            onToggle: () => _toggleItem(index),
                            onRemove: () => _removeItem(index),
                          ),
                        ),
                      ),
                      //item i listen
                      child: CheckListItem(
                        text: text,
                        isInFinishedList: isInFinishedList(index),
                        onToggle: () => _toggleItem(index),
                        onRemove: () => _removeItem(index),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  ///Her selve listene blir konstruert, basert på orientering (landskap/potrett)
  Widget build(BuildContext context) {
    super.build(context);

    final finishedItems = widget.items
        .asMap()
        .entries
        .where((item) => widget.finished[item.key])
        .toList();
    final unfinishedItems = widget.items
        .asMap()
        .entries
        .where((item) => !widget.finished[item.key])
        .toList();

    if (widget.isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: _landscapeXOffset),
          Expanded(
            child: Column(
              children: [

                Row(
                  children: [
                    TitleBox(title: widget.unfinishedTitle),
                    Expanded(
                      child: _constructHorizontalList(
                        unfinishedItems,
                        widget.unfinishedController,
                        canLeftPressUnfinished,
                        canRightPressUnfinished,
                        false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    TitleBox(title: widget.finishedTitle),
                    Expanded(
                      child: _constructHorizontalList(
                        finishedItems,
                        widget.finishedController,
                        canLeftPressFinished,
                        canRightPressFinished,
                        true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TitleBox(title: widget.unfinishedTitle, isLandscape: false),
            Expanded(
              child: _constructVerticalList(
                unfinishedItems,
                widget.unfinishedController,
                false,
              ),
            ),
            const SizedBox(height: 12),

            TitleBox(title: widget.finishedTitle, isLandscape: false),
            SizedBox(
              height: 200,
              child: _constructVerticalList(finishedItems, widget.finishedController, true),
            ),
          ],
        ),
      );
    }
  }
}