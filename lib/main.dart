import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const AutocompleteExampleApp());

class Arma {
  final String nome;
  final String elemento;
  final String material;

  Arma(this.nome, this.elemento, this.material);
}

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Autocomplete - Armas'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Escolha uma arma:'),
              const _AsyncAutocomplete(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsyncAutocomplete extends StatefulWidget {
  const _AsyncAutocomplete();

  @override
  State<_AsyncAutocomplete> createState() => _AsyncAutocompleteState();
}

class _AsyncAutocompleteState extends State<_AsyncAutocomplete> {
  String? _currentQuery;
  late Iterable<Arma> _lastOptions = <Arma>[];

  late final _Debounceable<Iterable<Arma>?, String> _debouncedSearch;

  Future<Iterable<Arma>?> _search(String query) async {
    _currentQuery = query;
    await Future<void>.delayed(fakeAPIDuration);

    if (_currentQuery != query) {
      return null;
    }

    _currentQuery = null;
    final armas = [
      Arma('Espada Asgard', 'Terra', 'Bronze'),
      Arma('Cajado Ruby', 'Fogo', 'Ferro'),
      Arma('Faca Cthulhu', 'Agua', 'Platina'),
      Arma('Arco e flecha Holy', 'Fogo', 'Ouro'),
      Arma('Machado hibernal', 'Gelo', 'Estanho'),
      Arma('Faca hibernal', 'Gelo', 'Estanho'),
    ];

    return armas.where((arma) =>
        arma.nome.toLowerCase().contains(query.toLowerCase()) || arma.elemento.toLowerCase().contains(query.toLowerCase()) || arma.material.toLowerCase().contains(query.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<Arma>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Arma>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<Arma>? options = await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      onSelected: (Arma selection) {
        debugPrint('Você selecionou a arma ${selection.nome} do elemento ${selection.elemento}, feita de ${selection.material}');
      },
      displayStringForOption: (Arma option) => option.nome + " (" + option.material.toLowerCase() + " + " + option.elemento.toLowerCase() +")",
    );
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

class _CancelException implements Exception {
  const _CancelException();
}
