// Heavily modified by Nitrous
// Portions Copyright (c) 2015 Nitrous, Inc. All Rights Reserved.
//
// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: http://codemirror.net/LICENSE

(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../vendor/codemirror/lib/codemirror"), require("../vendor/codemirror/addon/search/searchcursor"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../vendor/codemirror", "../vendor/codemirror/addon/search/searchcursor"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
  "use strict";
  function searchOverlay(query, caseInsensitive) {
    if (typeof query == "string")
      query = new RegExp(query.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), caseInsensitive ? "gi" : "g");
    else if (!query.global)
      query = new RegExp(query.source, query.ignoreCase ? "gi" : "g");

    return {token: function(stream) {
      query.lastIndex = stream.pos;
      var match = query.exec(stream.string);
      if (match && match.index == stream.pos) {
        stream.pos += match[0].length;
        return "searching";
      } else if (match) {
        stream.pos = match.index;
      } else {
        stream.skipToEnd();
      }
    }};
  }

  function SearchState() {
    this.posFrom = this.posTo = this.query = null;
    this.overlay = null;
  }
  function getSearchState(cm) {
    return cm.state.search || (cm.state.search = new SearchState());
  }
  function getSearchCursor(cm, query, pos, matchCase) {
    return cm.getSearchCursor(query, pos, !matchCase);
  }
  function parseQuery(query, isRE) {
    if (isRE) {
      try { query = new RegExp(query); }
      catch(e) { return; } // Not a regular expression after all, do a string search
    }
    return query;
  }

  function doSearch(cm, reverse, query, matchCase, useRegex) {
    var state = getSearchState(cm);
    if (state.query) return findNext(cm, reverse);
    return cm.operation(function() {
      if (!query || state.query) return false;
      state.query = parseQuery(query, useRegex);
      state.matchCase = matchCase;
      cm.removeOverlay(state.overlay, !matchCase);
      state.overlay = searchOverlay(state.query, !matchCase);
      cm.addOverlay(state.overlay);
      if (cm.showMatchesOnScrollbar) {
        if (state.annotate) { state.annotate.clear(); state.annotate = null; }
        state.annotate = cm.showMatchesOnScrollbar(state.query, !matchCase);
      }
      if (reverse) {
        cm.execCommand('goCharLeft');
      }
      state.posFrom = state.posTo = cm.getCursor();
      return findNext(cm, reverse);
    });
  }
  function findNext(cm, reverse) {return cm.operation(function() {
    var state = getSearchState(cm);
    var cursor = getSearchCursor(cm, state.query, reverse ? state.posFrom : state.posTo, state.matchCase);
    if (!cursor.find(reverse)) {
      cursor = getSearchCursor(cm, state.query, reverse ? CodeMirror.Pos(cm.lastLine()) : CodeMirror.Pos(cm.firstLine(), 0), state.matchCase);
      if (!cursor.find(reverse)) return false;
    }
    cm.setSelection(cursor.from(), cursor.to());
    cm.scrollIntoView({from: cursor.from(), to: cursor.to()});
    state.posFrom = cursor.from(); state.posTo = cursor.to();
    return true;
  });}
  function clearSearch(cm) {cm.operation(function() {
    var state = getSearchState(cm);
    if (!state.query) return;
    state.query = null;
    cm.removeOverlay(state.overlay);
    if (state.annotate) { state.annotate.clear(); state.annotate = null; }
  });}

  function replace(cm, all, query, text, matchCase, useRegex) {
    if (cm.getOption("readOnly")) return;
    if (!query) return;
    query = parseQuery(query, useRegex);
    if (all) {
      cm.operation(function() {
        for (var cursor = getSearchCursor(cm, query, 0, matchCase); cursor.findNext();) {
          if (typeof query != "string") {
            var match = cm.getRange(cursor.from(), cursor.to()).match(query);
            cursor.replace(text.replace(/\$(\d)/g, function(_, i) {return match[i];}));
          } else cursor.replace(text);
        }
      });
    } else {
      clearSearch(cm);
      cm.execCommand('goCharLeft');
      var cursor = getSearchCursor(cm, query, cm.getCursor(), matchCase);
      var advance = function(replace) {
        var start = cursor.from(), match;
        console.log(start, match);
        if (!(match = cursor.findNext())) {
          cursor = getSearchCursor(cm, query, 0, matchCase);
          if (!(match = cursor.findNext()) ||
              (start && cursor.from().line == start.line && cursor.from().ch == start.ch)) return;
        }
        cm.setSelection(cursor.from(), cursor.to());
        cm.scrollIntoView({from: cursor.from(), to: cursor.to()});
        if (replace) {
          doReplace(match);
        }
      };
      var doReplace = function(match) {
        cursor.replace(typeof query == "string" ? text :
                       text.replace(/\$(\d)/g, function(_, i) {return match[i];}));
        advance();
      };
      advance(true);
    }
  }

  CodeMirror.prototype.find = function(query, reverse, matchCase, useRegex) {
    clearSearch(this);
    return doSearch(this, reverse, query, matchCase, useRegex);
  };
  CodeMirror.prototype.findNext = function() {
    doSearch(this, false);
  };
  CodeMirror.prototype.findPrevious = function() {
    doSearch(this, true);
  };
  CodeMirror.prototype.clearSearch = function() {
    clearSearch(this);
  };
  CodeMirror.prototype.replace = function(query, text, all, matchCase, useRegex) {
    replace(this, all, query, text, matchCase, useRegex);
  };

  CodeMirror.commands.findNext = doSearch;
  CodeMirror.commands.findPrev = function(cm) {doSearch(cm, true);};
  CodeMirror.commands.clearSearch = clearSearch;
});
