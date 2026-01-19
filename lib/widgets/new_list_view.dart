import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///View for å lage ny liste
class NewList extends StatefulWidget {
  //Liste over navn til alle lister
  final List<String> listTitles;
  //Callback for å legge til en ny liste
  final Function(String) onAddList;

  const NewList({
    super.key,
    required this.listTitles,
    required this.onAddList,
  });

  @override
  State<NewList> createState() => _NewListState();
}

class _NewListState extends State<NewList> {
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _errorText;
  bool _inputFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _inputFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  ///Når en scroller til venstre i oversikt over alle lister
  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 100)
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }
  ///Når en scroller til høyre i oversikt over alle lister
  void _scrollRight() {
    final max =
    _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;
    final current = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final target = (current + 100).clamp(0.0, max);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  ButtonStyle _greenOutlinedButton({double? width}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.green, width: 2),
      minimumSize: Size(width ?? 0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  ///Legger til ny liste
  void _addNewList() {
    final text = _textController.text.trim();

    if (text.isEmpty || text.length > 10) {
      setState(() {
        _errorText = 'Navnet på listen må være mellom 1 og 5 tegn';
      });
      return;
    }

    if (widget.listTitles.contains(text)) {
      setState(() {
        _errorText = 'Listen finnes allerede';
      });
      return;
    }

    widget.onAddList(text);
    Navigator.pop(context);
  }

  Widget _constructScrollableTabs(bool isLandscape) {
    // Kun skjul tabs(oversikt over listene) når horisontal og input er i fokus
    if (isLandscape && _inputFocused) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_left_rounded, size: 36, color: Colors.black),
            onPressed: widget.listTitles.isEmpty ? null : _scrollLeft,
          ),
          Expanded(
            child: widget.listTitles.isEmpty
                ? const Center(
              child: Text(
                'Legg til en ny liste ved å trykke på knappen "Legg til liste"',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
                : SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < widget.listTitles.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => selectedIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == selectedIndex
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.listTitles[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: i == selectedIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right_rounded, size: 36, color: Colors.black),
            onPressed: widget.listTitles.isEmpty ? null : _scrollRight,
          ),
        ],
      ),
    );
  }

  Widget _constructInputArea(bool isLandscape) {
    final textField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey, width: 2),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Skriv inn navn på ny liste',
              hintStyle: TextStyle(color: Colors.black45),
              border: InputBorder.none,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            onSubmitted: (_) => _addNewList(),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            Expanded(child: textField),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addNewList,
              style: _greenOutlinedButton(),
              child: const Text('Legg til liste'),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            textField,
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addNewList,
              style: _greenOutlinedButton(width: double.infinity),
              child: const Text('Legg til liste'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape && !kIsWeb;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      //Når en klikker,så lukkes keyboard (er ikke lenger i fokus)
      //Om en klikker på tekstfeltet, så får en på nytt fokus,
      //etter å ha mistet fokus
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFC8E6C9),
        appBar: AppBar(
          title: const Text('Tilbake', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF2E7D32),
        ),
        body: Column(
          children: [
            _constructScrollableTabs(isLandscape),
            _constructInputArea(isLandscape),
          ],
        ),
      ),
    );
  }
}