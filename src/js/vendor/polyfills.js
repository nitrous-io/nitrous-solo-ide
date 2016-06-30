/*
  String
    - startsWith (ES6)
    - endsWith (ES6)
    - includes (ES6)

  Array
    + of (ES6)
    - includes (ES7)
    - find (ES6)
    - findIndex (ES6)

  Object
    + assign (ES6)

  ArrayBuffer
    - slice (ES6)
*/

if (!String.prototype.startsWith) {
  Object.defineProperty(String.prototype, 'startsWith', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: function(searchString, position) {
      position = position || 0;
      return this.lastIndexOf(searchString, position) === position;
    }
  });
}

if (!String.prototype.endsWith) {
  Object.defineProperty(String.prototype, 'endsWith', {
    value: function(searchString, position) {
      var subjectString = this.toString();
      if (position === undefined || position > subjectString.length) {
        position = subjectString.length;
      }
      position -= searchString.length;
      var lastIndex = subjectString.indexOf(searchString, position);
      return lastIndex !== -1 && lastIndex === position;
    }
  });
}

if (!String.prototype.includes) {
  String.prototype.includes = function() {'use strict';
    return String.prototype.indexOf.apply(this, arguments) !== -1;
  };
}

// Array polyfills

if (!Array.of) {
  Array.of = function() {
    return Array.prototype.slice.call(arguments);
  };
}

if (![].includes) {
  Array.prototype.includes = function(searchElement /*, fromIndex*/ ) {'use strict';
    var O = Object(this);
    var len = parseInt(O.length) || 0;
    if (len === 0) {
      return false;
    }
    var n = parseInt(arguments[1]) || 0;
    var k;
    if (n >= 0) {
      k = n;
    } else {
      k = len + n;
      if (k < 0) {k = 0;}
    }
    var currentElement;
    while (k < len) {
      currentElement = O[k];
      if (searchElement === currentElement ||
         (searchElement !== searchElement && currentElement !== currentElement)) {
        return true;
      }
      k++;
    }
    return false;
  };
}

if (!Array.prototype.find) {
  Array.prototype.find = function(predicate) {
    if (this == null) {
      throw new TypeError('Array.prototype.find called on null or undefined');
    }
    if (typeof predicate !== 'function') {
      throw new TypeError('predicate must be a function');
    }
    var list = Object(this);
    var length = list.length >>> 0;
    var thisArg = arguments[1];
    var value;

    for (var i = 0; i < length; i++) {
      value = list[i];
      if (predicate.call(thisArg, value, i, list)) {
        return value;
      }
    }
    return undefined;
  };
}

if (!Array.prototype.findIndex) {
  Array.prototype.findIndex = function(predicate) {
    if (this == null) {
      throw new TypeError('Array.prototype.findIndex called on null or undefined');
    }
    if (typeof predicate !== 'function') {
      throw new TypeError('predicate must be a function');
    }
    var list = Object(this);
    var length = list.length >>> 0;
    var thisArg = arguments[1];
    var value;

    for (var i = 0; i < length; i++) {
      value = list[i];
      if (predicate.call(thisArg, value, i, list)) {
        return i;
      }
    }
    return -1;
  };
}

if (!Object.assign) {
  Object.defineProperty(Object, 'assign', {
    enumerable: false,
    configurable: true,
    writable: true,
    value: function(target, firstSource) {
      'use strict';
      if (target === undefined || target === null) {
        throw new TypeError('Cannot convert first argument to object');
      }

      var to = Object(target);
      for (var i = 1; i < arguments.length; i++) {
        var nextSource = arguments[i];
        if (nextSource === undefined || nextSource === null) {
          continue;
        }

        var keysArray = Object.keys(Object(nextSource));
        for (var nextIndex = 0, len = keysArray.length; nextIndex < len; nextIndex++) {
          var nextKey = keysArray[nextIndex];
          var desc = Object.getOwnPropertyDescriptor(nextSource, nextKey);
          if (desc !== undefined && desc.enumerable) {
            to[nextKey] = nextSource[nextKey];
          }
        }
      }
      return to;
    }
  });
}

if (window.ArrayBuffer && !window.ArrayBuffer.prototype.slice) {
  //Returns a new ArrayBuffer whose contents are a copy of this ArrayBuffer's
  //bytes from `begin`, inclusive, up to `end`, exclusive
  ArrayBuffer.prototype.slice = function (begin, end) {
    //If `begin` is unspecified, Chrome assumes 0, so we do the same
    if (begin === void 0) {
      begin = 0;
    }

    //If `end` is unspecified, the new ArrayBuffer contains all
    //bytes from `begin` to the end of this ArrayBuffer.
    if (end === void 0) {
      end = this.byteLength;
    }

    //Chrome converts the values to integers via flooring
    begin = Math.floor(begin);
    end = Math.floor(end);

    //If either `begin` or `end` is negative, it refers to an
    //index from the end of the array, as opposed to from the beginning.
    if (begin < 0) {
      begin += this.byteLength;
    }
    if (end < 0) {
      end += this.byteLength;
    }

    //The range specified by the `begin` and `end` values is clamped to the
    //valid index range for the current array.
    begin = Math.min(Math.max(0, begin), this.byteLength);
    end = Math.min(Math.max(0, end), this.byteLength);

    //If the computed length of the new ArrayBuffer would be negative, it
    //is clamped to zero.
    if (end - begin <= 0) {
      return new ArrayBuffer(0);
    }

    var result = new ArrayBuffer(end - begin);
    var resultBytes = new Uint8Array(result);
    var sourceBytes = new Uint8Array(this, begin, end - begin);

    resultBytes.set(sourceBytes);

    return result;
  };
}
