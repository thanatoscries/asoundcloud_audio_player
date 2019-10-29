import 'dart:async';

import 'package:audio/src/services/audio_player_service.dart';
import 'package:audio/src/services/bloc/bloc.dart';
import 'package:audio/src/services/models/models.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService _audioPlayerService;
  int _trackDuration = 0;

  PlayerBloc({
    @required AudioPlayerService audioPlayerService,
  })  : assert(audioPlayerService != null),
        _audioPlayerService = audioPlayerService;

  @override
  PlayerState get initialState => PlayerState.stopped();

  @override
  void close() {
    _audioPlayerService.dispose();
    super.close();
  }

  @override
  Stream<PlayerState> mapEventToState(PlayerEvent event) async* {
    if (event is Pause) {
      yield* _pauseTune(event);
    } else if (event is PlayEvent) {
      yield* _playTune(event);
    } else if (event is Resume) {
      yield* _resumeTune(event);
    } else if (event is Stop) {
      yield* _stopTune(event);
    }
  }

  void toggle(Tune tune) {
    if (state == PlayerState.stopped()) {
      add(PlayEvent((b) => b..tune.replace(tune)));
    } else if (state == PlayerState.playing(0)) {
      add(Pause((b) => b));
    } else if (state == PlayerState.paused()) {
      add(Resume((b) => b));
    } else if (state == PlayerState.resumed()) {
      add(Pause((b) => b));
    }
  }

  Stream<PlayerState> _pauseTune(Pause event) async* {
    _audioPlayerService.pauseAudio();
    yield PlayerState.paused();
  }

  Stream<PlayerState> _playTune(PlayEvent event) async* {
    yield PlayerState.playing(0);
    _trackDuration = event.tune.audioFile.duration;
    _audioPlayerService.playAudio();
    _audioPlayerService.onProgress().listen(
          (p) => add(
            PlayEvent((b) => b..position = p.inMilliseconds),
          ),
        );
    yield* _positionDidUpdated(event);
  }

  Stream<PlayerState> _resumeTune(Resume event) async* {
    _audioPlayerService.resumeAudio();
    yield PlayerState.resumed();
  }

  Stream<PlayerState> _stopTune(Stop event) async* {
    _audioPlayerService.stopAudio();
    yield PlayerState.stopped();
  }

  Stream<PlayerState> _positionDidUpdated(PlayEvent event) async* {
    if (event.position >= _trackDuration) {
      yield PlayerState.stopped();
    } else if (event.position > 0 && event.position < _trackDuration) {
      yield PlayerState.playing(event.position);
    } else {
      yield PlayerState.paused();
    }
  }
}
