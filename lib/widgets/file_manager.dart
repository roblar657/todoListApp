import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Håndterer json filer tilknyttet sjekklister
class FileManager {
  /// Laster inn alle lagrede sjekklister fra filer
  static Future<Map<String, dynamic>> loadAllLists() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      final listNames = <String>[];
      final itemsList = <List<String>>[];
      final finishedStateList = <List<bool>>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final name = file.uri.pathSegments.last;
          final listName = name.replaceAll('.json', '');
          try {
            final content = await file.readAsString();
            final jsonData = jsonDecode(content);
            final finished = <String>[];
            final notFinished = <String>[];

            if (jsonData is Map) {
              if (jsonData['finished'] is List) {
                for (final itemName in (jsonData['finished'] as List)) {
                  if (itemName is String) finished.add(itemName);
                }
              }
              if (jsonData['notFinished'] is List) {
                for (final itemName in (jsonData['notFinished'] as List)) {
                  if (itemName is String) notFinished.add(itemName);
                }
              }
            }

            final items = <String>[];
            final itemsFinishedStates = <bool>[];
            for (final itemName in notFinished) {
              items.add(itemName);
              itemsFinishedStates.add(false);
            }
            for (final itemName in finished) {
              items.add(itemName);
              itemsFinishedStates.add(true);
            }

            listNames.add(listName);
            itemsList.add(items);
            finishedStateList.add(itemsFinishedStates);
          } catch (e) {

          }
        }
      }

      return {
        'listNames': listNames,
        'itemsList': itemsList,
        'finishedList': finishedStateList,
      };
    } catch (e) {
      return {
        'listNames': <String>[],
        'itemsList': <List<String>>[],
        'finishedList': <List<bool>>[],
      };
    }
  }

  /// Lagrer liste til fil basert på indeks
  static Future<void> saveListByIndex(
      int index,
      List<String> tabTitles,
      List<List<String>> items,
      List<List<bool>> finishedItems,
      ) async {
    if (index < 0 || index >= tabTitles.length) return;
    final listName = tabTitles[index];
    await _saveListToFile(listName, items[index], finishedItems[index]);
  }

  /// Lagrer liste til fil basert på navn
  static Future<void> saveListByName(
      String listName,
      List<String> items,
      List<bool> finishedItems,
      ) async {
    await _saveListToFile(listName, items, finishedItems);
  }

  /// Intern hjelpemetode for å lagre liste til fil
  static Future<void> _saveListToFile(
      String listName,
      List<String> items,
      List<bool> finishedItems,
      ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$listName.json';
      final file = File(filePath);

      final finished = <String>[];
      final notFinished = <String>[];

      for (int i = 0; i < items.length; i++) {
        if (i < finishedItems.length && finishedItems[i]) {
          finished.add(items[i]);
        } else {
          notFinished.add(items[i]);
        }
      }

      final jsonData = {
        'finished': finished,
        'notFinished': notFinished,
      };

      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {

    }
  }

  /// Sletter fil tilhørende liste
  static Future<void> deleteList(String listName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$listName.json';
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (e) {

    }
  }

  /// Opprett ny tom liste-fil
  static Future<void> createNewList(String listName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$listName.json';
      final file = File(filePath);
      final jsonData = {'finished': [], 'notFinished': []};
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {

    }
  }
}