// I18n.js
// =======
//
// This small library provides the Rails I18n API on the Javascript.
// You don't actually have to use Rails (or even Ruby) to use I18n.js.
// Just make sure you export all translations in an object like this:
//
//     I18n.translations.en = {
//       hello: "Hello World"
//     };
//
// See tests for specific formatting like numbers and dates.
//
;(function(I18n){
  "use strict";

  // Just cache the Array#slice function.
  var slice = Array.prototype.slice;

  // Apply number padding.
  var padding = function(number) {
    return ("0" + number.toString()).substr(-2);
  };

  // Set default days/months translations.
  var DATE = {
      day_names: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    , abbr_day_names: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    , month_names: [null, "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    , abbr_month_names: [null, "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    , meridian: ["AM", "PM"]
  };

  // Set default number format.
  var NUMBER_FORMAT = {
      precision: 3
    , separator: "."
    , delimiter: ","
    , strip_insignificant_zeros: false
  };

  // Set default currency format.
  var CURRENCY_FORMAT = {
      unit: "$"
    , precision: 2
    , format: "%u%n"
    , delimiter: ","
    , separator: "."
  };

  // Set default percentage format.
  var PERCENTAGE_FORMAT = {
      precision: 3
    , separator: "."
    , delimiter: ""
  };

  // Set default size units.
  var SIZE_UNITS = [null, "kb", "mb", "gb", "tb"];

  // Other default options
  var DEFAULT_OPTIONS = {
    defaultLocale: "en",
    locale: "en",
    defaultSeparator: ".",
    placeholder: /(?:\{\{|%\{)(.*?)(?:\}\}?)/gm,
    fallbacks: false,
    translations: {}
  };

  I18n.reset = function() {
    // Set default locale. This locale will be used when fallback is enabled and
    // the translation doesn't exist in a particular locale.
    this.defaultLocale = DEFAULT_OPTIONS.defaultLocale;

    // Set the current locale to `en`.
    this.locale = DEFAULT_OPTIONS.locale;

    // Set the translation key separator.
    this.defaultSeparator = DEFAULT_OPTIONS.defaultSeparator;

    // Set the placeholder format. Accepts `{{placeholder}}` and `%{placeholder}`.
    this.placeholder = DEFAULT_OPTIONS.placeholder;

    // Set if engine should fallback to the default locale when a translation
    // is missing.
    this.fallbacks = DEFAULT_OPTIONS.fallbacks;

    // Set the default translation object.
    this.translations = DEFAULT_OPTIONS.translations;
  };

  // Much like `reset`, but only assign options if not already assigned
  I18n.initializeOptions = function() {
    if (typeof(this.defaultLocale) === "undefined" && this.defaultLocale !== null)
      this.defaultLocale = DEFAULT_OPTIONS.defaultLocale;

    if (typeof(this.locale) === "undefined" && this.locale !== null)
      this.locale = DEFAULT_OPTIONS.locale;

    if (typeof(this.defaultSeparator) === "undefined" && this.defaultSeparator !== null)
      this.defaultSeparator = DEFAULT_OPTIONS.defaultSeparator;

    if (typeof(this.placeholder) === "undefined" && this.placeholder !== null)
      this.placeholder = DEFAULT_OPTIONS.placeholder;

    if (typeof(this.fallbacks) === "undefined" && this.fallbacks !== null)
      this.fallbacks = DEFAULT_OPTIONS.fallbacks;

    if (typeof(this.translations) === "undefined" && this.translations !== null)
      this.translations = DEFAULT_OPTIONS.translations;
  };
  I18n.initializeOptions();

  // Return a list of all locales that must be tried before returning the
  // missing translation message. By default, this will consider the inline option,
  // current locale and fallback locale.
  //
  //     I18n.locales.get("de-DE");
  //     // ["de-DE", "de", "en"]
  //
  // You can define custom rules for any locale. Just make sure you return a array
  // containing all locales.
  //
  //     // Default the Wookie locale to English.
  //     I18n.locales["wk"] = function(locale) {
  //       return ["en"];
  //     };
  //
  I18n.locales = {};

  // Retrieve locales based on inline locale, current locale or default to
  // I18n's detection.
  I18n.locales.get = function(locale) {
    var result = this[locale] || this[I18n.locale] || this["default"];

    if (typeof(result) === "function") {
      result = result(locale);
    }

    if (result instanceof Array === false) {
      result = [result];
    }

    return result;
  };

  // The default locale list.
  I18n.locales["default"] = function(locale) {
    var locales = []
      , list = []
      , countryCode
      , count
    ;

    // Handle the inline locale option that can be provided to
    // the `I18n.t` options.
    if (locale) {
      locales.push(locale);
    }

    // Add the current locale to the list.
    if (!locale && I18n.locale) {
      locales.push(I18n.locale);
    }

    // Add the default locale if fallback strategy is enabled.
    if (I18n.fallbacks && I18n.defaultLocale) {
      locales.push(I18n.defaultLocale);
    }

    // Compute each locale with its country code.
    // So this will return an array containing both
    // `de-DE` and `de` locales.
    locales.forEach(function(locale){
      countryCode = locale.split("-")[0];

      if (!~list.indexOf(locale)) {
        list.push(locale);
      }

      if (I18n.fallbacks && countryCode && countryCode !== locale && !~list.indexOf(countryCode)) {
        list.push(countryCode);
      }
    });

    // No locales set? English it is.
    if (!locales.length) {
      locales.push("en");
    }

    return list;
  };

  // Hold pluralization rules.
  I18n.pluralization = {};

  // Return the pluralizer for a specific locale.
  // If no specify locale is found, then I18n's default will be used.
  I18n.pluralization.get = function(locale) {
    return this[locale] || this[I18n.locale] || this["default"];
  };

  // The default pluralizer rule.
  // It detects the `zero`, `one`, and `other` scopes.
  I18n.pluralization["default"] = function(count) {
    switch (count) {
      case 0: return ["zero", "other"];
      case 1: return ["one"];
      default: return ["other"];
    }
  };

  // Return current locale. If no locale has been set, then
  // the current locale will be the default locale.
  I18n.currentLocale = function() {
    return this.locale || this.defaultLocale;
  };

  // Check if value is different than undefined and null;
  I18n.isSet = function(value) {
    return value !== undefined && value !== null;
  };

  // Find and process the translation using the provided scope and options.
  // This is used internally by some functions and should not be used as an
  // public API.
  I18n.lookup = function(scope, options) {
    options = this.prepareOptions(options);

    var locales = this.locales.get(options.locale).slice()
      , requestedLocale = locales[0]
      , locale
      , scopes
      , translations
    ;

    // Deal with the scope as an array.
    if (scope.constructor === Array) {
      scope = scope.join(this.defaultSeparator);
    }

    // Deal with the scope option provided through the second argument.
    //
    //    I18n.t('hello', {scope: 'greetings'});
    //
    if (options.scope) {
      scope = [options.scope, scope].join(this.defaultSeparator);
    }

    while (locales.length) {
      locale = locales.shift();
      scopes = scope.split(this.defaultSeparator);
      translations = this.translations[locale];

      if (!translations) {
        continue;
      }

      while (scopes.length) {
        translations = translations[scopes.shift()];

        if (translations === undefined || translations === null) {
          break;
        }
      }

      if (translations !== undefined && translations !== null) {
        return translations;
      }
    }

    if (this.isSet(options.defaultValue)) {
      return options.defaultValue;
    }
  };

  // Rails changed the way the meridian is stored.
  // It started with `date.meridian` returning an array,
  // then it switched to `time.am` and `time.pm`.
  // This function abstracts this difference and returns
  // the correct meridian or the default value when none is provided.
  I18n.meridian = function() {
    var time = this.lookup("time");
    var date = this.lookup("date");

    if (time && time.am && time.pm) {
      return [time.am, time.pm];
    } else if (date && date.meridian) {
      return date.meridian;
    } else {
      return DATE.meridian;
    }
  };

  // Merge serveral hash options, checking if value is set before
  // overwriting any value. The precedence is from left to right.
  //
  //     I18n.prepareOptions({name: "John Doe"}, {name: "Mary Doe", role: "user"});
  //     #=> {name: "John Doe", role: "user"}
  //
  I18n.prepareOptions = function() {
    var args = slice.call(arguments)
      , options = {}
      , subject
    ;

    while (args.length) {
      subject = args.shift();

      if (typeof(subject) != "object") {
        continue;
      }

      for (var attr in subject) {
        if (!subject.hasOwnProperty(attr)) {
          continue;
        }

        if (this.isSet(options[attr])) {
          continue;
        }

        options[attr] = subject[attr];
      }
    }

    return options;
  };

  // Generate a list of translation options for default fallbacks.
  // `defaultValue` is also deleted from options as it is returned as part of
  // the translationOptions array.
  I18n.createTranslationOptions = function(scope, options) {
    var translationOptions = [{scope: scope}];

    // Defaults should be an array of hashes containing either
    // fallback scopes or messages
    if (this.isSet(options.defaults)) {
      translationOptions = translationOptions.concat(options.defaults);
    }

    // Maintain support for defaultValue. Since it is always a message
    // insert it in to the translation options as such.
    if (this.isSet(options.defaultValue)) {
      translationOptions.push({ message: options.defaultValue });
      delete options.defaultValue;
    }

    return translationOptions;
  };

  // Translate the given scope with the provided options.
  I18n.translate = function(scope, options) {
    options = this.prepareOptions(options);

    var translationOptions = this.createTranslationOptions(scope, options);

    var translation;
    // Iterate through the translation options until a translation
    // or message is found.
    var translationFound =
      translationOptions.some(function(translationOption) {
        if (this.isSet(translationOption.scope)) {
          translation = this.lookup(translationOption.scope, options);
        } else if (this.isSet(translationOption.message)) {
          translation = translationOption.message;
        }

        if (translation !== undefined && translation !== null) {
          return true;
        }
      }, this);

    if (!translationFound) {
      return this.missingTranslation(scope);
    }

    if (typeof(translation) === "string") {
      translation = this.interpolate(translation, options);
    } else if (translation instanceof Object && this.isSet(options.count)) {
      translation = this.pluralize(options.count, translation, options);
    }

    return translation;
  };

  // This function interpolates the all variables in the given message.
  I18n.interpolate = function(message, options) {
    options = this.prepareOptions(options);
    var matches = message.match(this.placeholder)
      , placeholder
      , value
      , name
      , regex
    ;

    if (!matches) {
      return message;
    }

    var value;

    while (matches.length) {
      placeholder = matches.shift();
      name = placeholder.replace(this.placeholder, "$1");

      if (this.isSet(options[name])) {
        value = options[name].toString().replace(/\$/gm, "_#$#_");
      } else {
        value = this.missingPlaceholder(placeholder, message);
      }

      regex = new RegExp(placeholder.replace(/\{/gm, "\\{").replace(/\}/gm, "\\}"));
      message = message.replace(regex, value);
    }

    return message.replace(/_#\$#_/g, "$");
  };

  // Pluralize the given scope using the `count` value.
  // The pluralized translation may have other placeholders,
  // which will be retrieved from `options`.
  I18n.pluralize = function(count, scope, options) {
    options = this.prepareOptions(options);
    var translations, pluralizer, keys, key, message;

    if (scope instanceof Object) {
      translations = scope;
    } else {
      translations = this.lookup(scope, options);
    }

    if (!translations) {
      return this.missingTranslation(scope);
    }

    pluralizer = this.pluralization.get(options.locale);
    keys = pluralizer(Math.abs(count));

    while (keys.length) {
      key = keys.shift();

      if (this.isSet(translations[key])) {
        message = translations[key];
        break;
      }
    }

    options.count = String(count);
    return this.interpolate(message, options);
  };

  // Return a missing translation message for the given parameters.
  I18n.missingTranslation = function(scope) {
    var message = '[missing "';

    message += this.currentLocale() + ".";
    message += slice.call(arguments).join(".");
    message += '" translation]';

    return message;
  };

  // Return a missing placeholder message for given parameters
  I18n.missingPlaceholder = function(placeholder, message) {
    return "[missing " + placeholder + " value]";
  };

  // Format number using localization rules.
  // The options will be retrieved from the `number.format` scope.
  // If this isn't present, then the following options will be used:
  //
  // - `precision`: `3`
  // - `separator`: `"."`
  // - `delimiter`: `","`
  // - `strip_insignificant_zeros`: `false`
  //
  // You can also override these options by providing the `options` argument.
  //
  I18n.toNumber = function(number, options) {
    options = this.prepareOptions(
        options
      , this.lookup("number.format")
      , NUMBER_FORMAT
    );

    var negative = number < 0
      , string = Math.abs(number).toFixed(options.precision).toString()
      , parts = string.split(".")
      , precision
      , buffer = []
      , formattedNumber
    ;

    number = parts[0];
    precision = parts[1];

    while (number.length > 0) {
      buffer.unshift(number.substr(Math.max(0, number.length - 3), 3));
      number = number.substr(0, number.length -3);
    }

    formattedNumber = buffer.join(options.delimiter);

    if (options.strip_insignificant_zeros && precision) {
      precision = precision.replace(/0+$/, "");
    }

    if (options.precision > 0 && precision) {
      formattedNumber += options.separator + precision;
    }

    if (negative) {
      formattedNumber = "-" + formattedNumber;
    }

    return formattedNumber;
  };

  // Format currency with localization rules.
  // The options will be retrieved from the `number.currency.format` and
  // `number.format` scopes, in that order.
  //
  // Any missing option will be retrieved from the `I18n.toNumber` defaults and
  // the following options:
  //
  // - `unit`: `"$"`
  // - `precision`: `2`
  // - `format`: `"%u%n"`
  // - `delimiter`: `","`
  // - `separator`: `"."`
  //
  // You can also override these options by providing the `options` argument.
  //
  I18n.toCurrency = function(number, options) {
    options = this.prepareOptions(
        options
      , this.lookup("number.currency.format")
      , this.lookup("number.format")
      , CURRENCY_FORMAT
    );

    number = this.toNumber(number, options);
    number = options.format
      .replace("%u", options.unit)
      .replace("%n", number)
    ;

    return number;
  };

  // Localize several values.
  // You can provide the following scopes: `currency`, `number`, or `percentage`.
  // If you provide a scope that matches the `/^(date|time)/` regular expression
  // then the `value` will be converted by using the `I18n.toTime` function.
  //
  // It will default to the value's `toString` function.
  //
  I18n.localize = function(scope, value) {
    switch (scope) {
      case "currency":
        return this.toCurrency(value);
      case "number":
        scope = this.lookup("number.format");
        return this.toNumber(value, scope);
      case "percentage":
        return this.toPercentage(value);
      default:
        if (scope.match(/^(date|time)/)) {
          return this.toTime(scope, value);
        } else {
          return value.toString();
        }
    }
  };

  // Parse a given `date` string into a JavaScript Date object.
  // This function is time zone aware.
  //
  // The following string formats are recognized:
  //
  //    yyyy-mm-dd
  //    yyyy-mm-dd[ T]hh:mm::ss
  //    yyyy-mm-dd[ T]hh:mm::ss
  //    yyyy-mm-dd[ T]hh:mm::ssZ
  //    yyyy-mm-dd[ T]hh:mm::ss+0000
  //    yyyy-mm-dd[ T]hh:mm::ss+00:00
  //    yyyy-mm-dd[ T]hh:mm::ss.123Z
  //
  I18n.parseDate = function(date) {
    var matches, convertedDate, fraction;
    // we have a date, so just return it.
    if (typeof(date) == "object") {
      return date;
    };

    matches = date.toString().match(/(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2})([\.,]\d{1,3})?)?(Z|\+00:?00)?/);

    if (matches) {
      for (var i = 1; i <= 6; i++) {
        matches[i] = parseInt(matches[i], 10) || 0;
      }

      // month starts on 0
      matches[2] -= 1;

      fraction = matches[7] ? 1000 * ("0" + matches[7]) : null;

      if (matches[8]) {
        convertedDate = new Date(Date.UTC(matches[1], matches[2], matches[3], matches[4], matches[5], matches[6], fraction));
      } else {
        convertedDate = new Date(matches[1], matches[2], matches[3], matches[4], matches[5], matches[6], fraction);
      }
    } else if (typeof(date) == "number") {
      // UNIX timestamp
      convertedDate = new Date();
      convertedDate.setTime(date);
    } else if (date.match(/([A-Z][a-z]{2}) ([A-Z][a-z]{2}) (\d+) (\d+:\d+:\d+) ([+-]\d+) (\d+)/)) {
      // This format `Wed Jul 20 13:03:39 +0000 2011` is parsed by
      // webkit/firefox, but not by IE, so we must parse it manually.
      convertedDate = new Date();
      convertedDate.setTime(Date.parse([
        RegExp.$1, RegExp.$2, RegExp.$3, RegExp.$6, RegExp.$4, RegExp.$5
      ].join(" ")));
    } else if (date.match(/\d+ \d+:\d+:\d+ [+-]\d+ \d+/)) {
      // a valid javascript format with timezone info
      convertedDate = new Date();
      convertedDate.setTime(Date.parse(date));
    } else {
      // an arbitrary javascript string
      convertedDate = new Date();
      convertedDate.setTime(Date.parse(date));
    }

    return convertedDate;
  };

  // Formats time according to the directives in the given format string.
  // The directives begins with a percent (%) character. Any text not listed as a
  // directive will be passed through to the output string.
  //
  // The accepted formats are:
  //
  //     %a  - The abbreviated weekday name (Sun)
  //     %A  - The full weekday name (Sunday)
  //     %b  - The abbreviated month name (Jan)
  //     %B  - The full month name (January)
  //     %c  - The preferred local date and time representation
  //     %d  - Day of the month (01..31)
  //     %-d - Day of the month (1..31)
  //     %H  - Hour of the day, 24-hour clock (00..23)
  //     %-H - Hour of the day, 24-hour clock (0..23)
  //     %I  - Hour of the day, 12-hour clock (01..12)
  //     %-I - Hour of the day, 12-hour clock (1..12)
  //     %m  - Month of the year (01..12)
  //     %-m - Month of the year (1..12)
  //     %M  - Minute of the hour (00..59)
  //     %-M - Minute of the hour (0..59)
  //     %p  - Meridian indicator (AM  or  PM)
  //     %S  - Second of the minute (00..60)
  //     %-S - Second of the minute (0..60)
  //     %w  - Day of the week (Sunday is 0, 0..6)
  //     %y  - Year without a century (00..99)
  //     %-y - Year without a century (0..99)
  //     %Y  - Year with century
  //     %z  - Timezone offset (+0545)
  //
  I18n.strftime = function(date, format) {
    var options = this.lookup("date")
      , meridianOptions = I18n.meridian()
    ;

    if (!options) {
      options = {};
    }

    options = this.prepareOptions(options, DATE);

    var weekDay = date.getDay()
      , day = date.getDate()
      , year = date.getFullYear()
      , month = date.getMonth() + 1
      , hour = date.getHours()
      , hour12 = hour
      , meridian = hour > 11 ? 1 : 0
      , secs = date.getSeconds()
      , mins = date.getMinutes()
      , offset = date.getTimezoneOffset()
      , absOffsetHours = Math.floor(Math.abs(offset / 60))
      , absOffsetMinutes = Math.abs(offset) - (absOffsetHours * 60)
      , timezoneoffset = (offset > 0 ? "-" : "+") +
          (absOffsetHours.toString().length < 2 ? "0" + absOffsetHours : absOffsetHours) +
          (absOffsetMinutes.toString().length < 2 ? "0" + absOffsetMinutes : absOffsetMinutes)
    ;

    if (hour12 > 12) {
      hour12 = hour12 - 12;
    } else if (hour12 === 0) {
      hour12 = 12;
    }

    format = format.replace("%a", options.abbr_day_names[weekDay]);
    format = format.replace("%A", options.day_names[weekDay]);
    format = format.replace("%b", options.abbr_month_names[month]);
    format = format.replace("%B", options.month_names[month]);
    format = format.replace("%d", padding(day));
    format = format.replace("%e", day);
    format = format.replace("%-d", day);
    format = format.replace("%H", padding(hour));
    format = format.replace("%-H", hour);
    format = format.replace("%I", padding(hour12));
    format = format.replace("%-I", hour12);
    format = format.replace("%m", padding(month));
    format = format.replace("%-m", month);
    format = format.replace("%M", padding(mins));
    format = format.replace("%-M", mins);
    format = format.replace("%p", meridianOptions[meridian]);
    format = format.replace("%S", padding(secs));
    format = format.replace("%-S", secs);
    format = format.replace("%w", weekDay);
    format = format.replace("%y", padding(year));
    format = format.replace("%-y", padding(year).replace(/^0+/, ""));
    format = format.replace("%Y", year);
    format = format.replace("%z", timezoneoffset);

    return format;
  };

  // Convert the given dateString into a formatted date.
  I18n.toTime = function(scope, dateString) {
    var date = this.parseDate(dateString)
      , format = this.lookup(scope)
    ;

    if (date.toString().match(/invalid/i)) {
      return date.toString();
    }

    if (!format) {
      return date.toString();
    }

    return this.strftime(date, format);
  };

  // Convert a number into a formatted percentage value.
  I18n.toPercentage = function(number, options) {
    options = this.prepareOptions(
        options
      , this.lookup("number.percentage.format")
      , this.lookup("number.format")
      , PERCENTAGE_FORMAT
    );

    number = this.toNumber(number, options);
    return number + "%";
  };

  // Convert a number into a readable size representation.
  I18n.toHumanSize = function(number, options) {
    var kb = 1024
      , size = number
      , iterations = 0
      , unit
      , precision
    ;

    while (size >= kb && iterations < 4) {
      size = size / kb;
      iterations += 1;
    }

    if (iterations === 0) {
      unit = this.t("number.human.storage_units.units.byte", {count: size});
      precision = 0;
    } else {
      unit = this.t("number.human.storage_units.units." + SIZE_UNITS[iterations]);
      precision = (size - Math.floor(size) === 0) ? 0 : 1;
    }

    options = this.prepareOptions(
        options
      , {precision: precision, format: "%n%u", delimiter: ""}
    );

    number = this.toNumber(size, options);
    number = options.format
      .replace("%u", unit)
      .replace("%n", number)
    ;

    return number;
  };

  // Set aliases, so we can save some typing.
  I18n.t = I18n.translate;
  I18n.l = I18n.localize;
  I18n.p = I18n.pluralize;
})(typeof(exports) === "undefined" ? (this.I18n || (this.I18n = {})) : exports);
I18n.translations = {"es":{"brand":"Cointrade","submit":"Enviar","cancel":"Cancelar","confirm":"Confirmar","banks":{"_065":"Andbank","_654":"Banco A.j. Renner S.A.","_246":"Banco Abc/brasil S.A.","_121":"Banco Agibank S.A.","_025":"Banco Alfa S.A.","_213":"Banco Arbi S.A.","_096":"Banco B3 S.A.","_036":"Banco Bem S.a..","_122":"Banco Berj S.A.","_318":"Banco Bmg Comercial S.A.","_752":"Banco Bnp Paribas Brasil S.A.","_107":"Banco Bocom Bbm S.A.","_069":"Banco Bpn Brasil S.A.","_063":"Banco Bradescard S.A.","_237":"Banco Bradesco S.A.","_218":"Banco Bs2 S.A.","_473":"Banco Caixa Geral Brasil S.A.","_412":"Banco Capital S.A.","_040":"Banco Cargill S.A.","_266":"Banco Cedula S.A.","_745":"Banco Citibank S.A.","_756":"Banco Cooperativo do Brasil S.A.","_748":"Banco Cooperativo Sicredi S.A.","_505":"Banco Credit Suisse (brasil) S.A.","_003":"Banco da Amazonia S.A.","_083":"Banco da China Brasil S.A.","_707":"Banco Daycoval S.A.","_070":"Banco de Brasilia S.A.","_300":"Banco de La Nacion Argentina S.A.","_487":"Banco Deutsche Bank S.A.","_001":"Banco do Brasil S.A.","_047":"Banco do Estado de Sergipe S.A.","_021":"Banco do Estado do Espirito Santo S.A.","_037":"Banco do Estado do Para S.A.","_041":"Banco do Estado do Rio Grande do Sul S.A.","_004":"Banco do Nordeste do Brasil S.A.","_265":"Banco Fator S.A.","_224":"Banco Fibra S.A.","_626":"Banco Ficsa S.A.","_394":"Banco Finasa Bmc S.A.","_612":"Banco Guanabara S.A.","_604":"Banco Industrial do Brasil S.A.","_653":"Banco Indusval S.A.","_077":"Banco Intermedium","_074":"Banco J. Safra S.A.","_376":"Banco Jp Morgan S.A.","_600":"Banco Luso Brasileiro S.A.","_389":"Banco Mercantil do Brasil S.A.","_755":"Banco Merrill Lynch S.A.","_746":"Banco Modal S.A.","_456":"Banco Mufg Brasil S.A.","_079":"Banco Original do Agronegocio S.A.","_212":"Banco Original S.A.","_208":"Banco Pactual S.A.","_623":"Banco Pan","_254":"Banco Parana Banco S.A.","_611":"Banco Paulista S.A.","_643":"Banco Pine S.A.","_747":"Banco Rabobank International Br S.A.","_633":"Banco Rendimento S.A.","_741":"Banco Ribeirao Preto S.A.","_422":"Banco Safra S.A.","_033":"Banco Santander S.A.","_743":"Banco Semear S.A.","_366":"Banco Societe Generale Brasil S.A.","_637":"Banco Sofisa","_243":"Banco Stock Maxima S.A.","_464":"Banco Sumitomo Mitsui Brasileiro S.A.","_634":"Banco Triangulo S.A.","_018":"Banco Tricury S.A.","_655":"Banco Votorantim S.A.","_610":"Banco Vr S.A.","_222":"Bco Credit Agricole Brasil S.A.","_017":"Bny Mellon Banco S.A.","_125":"Brasil Plural S.A.","_097":"Cc Centralcredi","_136":"Cc Unicred do Brasil","_320":"Ccb Brasil","_098":"Cerdialinca Cooperativa Credito Rural","_739":"Cetelem","_163":"Commerzbank","_085":"Cooperativa Central de Credito / Ailos","_099":"Cooperativa Central Econ. Cred. Mutuo Un","_089":"Cooperativa de Credito Rural da Regiao D","_010":"Credicoamo Credito Rural Cooperativa","_104":"Cx Economica Federal","_094":"Finaxis","_132":"Icbc do Brasil Banco Multiplo S.A.","_630":"Intercap","_341":"Itaú Unibanco S.A.","_076":"Kdb do Brasil","_757":"Keb Hana do Brasil","_753":"Nbc Bank Brasil Sa/banco Multiplo","_260":"Nu Pagamentos S.A.","_613":"Omni Banco S A","_120":"Rodobens","_751":"Scotiabank Brasil S.a. Banco Multiplo","_082":"Topazio","_084":"Uniprime Norte do Parana Cc","_119":"Western Union","_124":"Woori Bank"},"fund_sources":{"manage_bank_account":"Gestión de Cuentas Bancarias","manage_bank_account_desc":"Para facilitar la elección de la dirección de retiros bancarios","manage_bank_account_alert":"Su número brasileño de CPF es obligatorio para el retiro de Reals","manage_bank_account_info":"* Atención Si el dígito de su banco es X, por favor sustituya 0.","manage_bank_account_required":"Todos los campos son obligatorios.","manage_coin_address":"Gestión de Direcciones de Monedas","manage_coin_address_desc":"Para facilitar la elección de la dirección de retiros de monedas","bank":"Banco","account":"Cuenta","cpf":"CPF/CNPJ","agency":"Agencia","account-dig":"Cuenta-dig","digit":"dig","label":"Etiqueta","address":"Dirección","action":"Acción","add":"Añadir","remove":"Retirar","default":"Estándar"},"payment_slip":{"bank":"Banco","label_name":"Nome","label_cpf":"CPF","label_cnpj":"CNPJ","label_cpfcnpj":"CPF ou CNPJ","label_phone":"Num.Celular","label_email":"E-mail","label_address":"Direccion","label_city":"Ciudad","label_uf":"UF","label_state":"Estado","label_cep":"CEP","label_complement":"Complemento","label_number":"Número","title":"Generación del boleto","label":"Apelido","address":"Endereço","action":"Acción","add":"Añadir","remove":"Retirar","default":"Estándar","desc":"Los datos aquí informados serán utilizados en la generación del boleto.","btn_generete_slip":"Gerar Boleto","label_amount":"R$ 00000","value_req":"Los datos aquí","label_tabDeposit":"Depósitos","label_tabBank":"Boleto","amount":"Valor","tax":"Taxa"},"funds":{"deposit":"Depósito","withdraw":"Retirar","tooltip_status":{"accepted":{"text":"El Txid informado se procesó correctamente. Por favor verifique en su Saldo.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"checked":{"text":"Ordenada por el administrador.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"submitting":{"text":"Se está procesando el Txid.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitted":{"text":"Se ha enviado la orden de depósito.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"cancelled":{"text":"Orden cancelada.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"rejected":{"text":"Orden rechazado. Por favor, contacte nuestro soporte.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"warning":{"text":"El Txid no ha sido procesado en las últimas 2 horas. Por favor, contacte nuestro soporte.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"}},"currency_name":{"btc":"BTC","brl":"BRL","doge":"DOGE","pts":"PTS","ltc":"LTC","bch":"BCH","btg":"BTG","dash":"DASH","eth":"ETH","zec":"ZEC","dgb":"DGB","xrp":"XRP","smart":"Smart","iota":"IOTA","zcr":"ZCR","tusd":"TUSD","xem":"XEM","rbtc":"RBTC","rif":"RIF","xar":"XAR"},"deposit_brl":{"title":"Depósito Real Brasileño","desc":"Siga los pasos siguientes:","desc_item_1":"1. Vaya a la opción (Administrar cuentas) y agregue su información bancaria.","desc_item_2":"2. Ingrese el monto de su depósito y haga clic en el botón Enviar","desc_item_3":"3. Continúe con su transferencia bancaria a la cuenta bancaria de COINBR SERVICOS DIGITAIS LTDA","desc_item_4":"SIEMPRE usar nuestra cuenta ITAÚ para TEDs y TEFs","desc_item_5":null,"desc_item_6":"(Información provista a continuación)","desc_item_7":"4. SIEMPRE envíe su recibo de depósito a \u003Ccomprovante@cointrade.cx\u003E. Su depósito será confirmado tan pronto como recibamos su dinero","attention":"Atención: NO aceptamos transferencias de diferentes titulares de cuentas, sujeto a una tarifa de reembolso del 10%. El nombre de su cuenta bancaria debe coincidir con el nombre de su Registro de Cointrade; de lo contrario, no se identificará su depósito.","from":"Desde","to":"Hasta","deposit_name":"Tu nombre","deposit_account":"Cuenta de depósito","add":"Añadir","manage":"GESTIONAR","amount":"VALOR","type":"Tipo","document":"CPF","document_mask":"000.000.000-00","min_amount":"Al menos 25,00 Reais brasileños","to_account":"TED/DOC","account_detail":"Itaú Ag: 7307 Conta: 08782-0","to_name":"Nombre","to_bank_name":"Nombre del banco","opening_bank_name":"Registro Brasileño CNPJ","remark":"Código de Referencia (Código de identificación de transferencia)","label_deposit_value":"Valor de depósito","label_deposit_ammount":"Seleccione el tipo de transacción?","label_deposit_vlr":"Valor del depósito.","label_desc":"¿De qué tipo se hará la transacción?","deposit_information_title":"¡ADVERTENCIA! INFORMACIÓN DE COMO REALIZAR EL DEPOSITO"},"deposit_btc":{"title":"Depósito de BTC"},"deposit_bch":{"title":"Depósito de BCH"},"deposit_btg":{"title":"Depósito de BTG"},"deposit_dash":{"title":"Depósito de DASH"},"deposit_eth":{"title":"Depósito de ETH"},"deposit_zec":{"title":"Depósito de ZEC"},"deposit_dgb":{"title":"Depósito de DGB"},"deposit_xrp":{"title":"Depósito de XRP"},"deposit_smart":{"title":"Depósito de Smart"},"deposit_iota":{"title":"Depósito de IOTA"},"deposit_ltc":{"title":"Depósito de LTC"},"deposit_zcr":{"title":"Depósito de ZCR"},"deposit_tusd":{"title":"Depósito de TUSD"},"deposit_xem":{"title":"XEM Deposit"},"deposit_rbtc":{"title":"RBTC Deposit"},"deposit_rif":{"title":"RIF Deposit"},"deposit_xar":{"title":"XAR Deposit"},"deposit_coin":{"address":"Dirección","new_address":"Nueva direccion","confirm_gen_new_address":"¿Seguro que quieres generar una nueva dirección de depósito?","open-wallet":"Utilice sus servicios comunes de billetera, billetera local, terminal móvil o billetera virtual, seleccione un pago y envíe.","detail":"Por favor, pegue la dirección abajo en su cartera, llene el valor que desea depositar, confirme y envíe.","scan-qr":"Escanear el código QR para pagar en la billetera de la terminal móvil.","after_deposit":"Una vez que complete el envío, puede verificar el estado de su nuevo depósito a continuación.","generate-new":"Generar nueva dirección","copy":"Copiar"},"deposit_history":{"title":"Historial de depósitos","number":"#","identification":"Código de identificación","time":"Hora","txid":"ID de transacción","confirmations":"Confirmaciones","from":"Desde","imformation_from":"Información de la transacción","amount":"Cantidad","state_and_action":"Estado/Acción","cancel":"cancelar","no_data":"No hay datos de historial","validator":"Validador","submitting":"Sumisión","cancelled":"Cancelado","submitted":"Presentada","accepted":"Aceptado","rejected":"Rechazado","checked":"Comprobado","warning":"Advertencia","suspect":"Sospechoso"},"withdraw_brl":{"title":"Retiro Real Brasileño","intro":"Seleccione el banco para rescatar el valor y entre el número de cuenta corriente para completar el envío.","intro_2":"Su cuenta bancaria y su nombre deben ser consistentes con el nombre de autentificación del nombre real.","attention":"Horas laborales: 9:00 - 18:00","account_name":"Nombre de la cuenta","withdraw_address":"Cuenta de destino","balance":"Balance","withdraw_amount":"Valor de Rescate","manage_withdraw":"Administrar Retirada","fee_explain":"Sobre la tarifa","min":"Al menos","withdraw_all":"Retirar todo"},"withdraw_btc":{"title":"Retirada de BTC"},"withdraw_bch":{"title":"Retirada de BCH"},"withdraw_btg":{"title":"Retirada de BTG"},"withdraw_dash":{"title":"Retirada de DASH"},"withdraw_eth":{"title":"Retirada de ETH"},"withdraw_zec":{"title":"Retirada de ZEC"},"withdraw_dgb":{"title":"Retirada de DGB"},"withdraw_xrp":{"title":"Retirada de XRP"},"withdraw_smart":{"title":"Retirada de Smart"},"withdraw_iota":{"title":"Retirada de IOTA"},"withdraw_ltc":{"title":"Retirada de LTC"},"withdraw_zcr":{"title":"Retirada de ZCR"},"withdraw_tusd":{"title":"Retirada de TUSD"},"withdraw_coin":{"intro":"Por favor, complete la dirección y el monto, luego envíe el formulario.","label":"Etiqueta","balance":"Balance","amount":"Cantidad","manage_withdraw":"Administrar dirección","min":"Al menos","withdraw_all":"Retirar todo","fee_explain":"Sobre la tarifa","with":"Amount of withdrawal fee."},"withdraw_history":{"title":"Historial de Resgates","number":"Número","withdraw_time":"Hora","withdraw_account":"Cuenta de rescate","withdraw_address":"Dirección","withdraw_amount":"Cantidad","actual_amount":"Cantidad Actual","fee":"Cuota","miner_fee":"Cuota","state_and_action":"Estado/Acción","cancel":"Cancelar","no_data":"No hay datos de historial","submitting":"Sumisión","submitted":"Presentada","rejected":"Rechazado","accepted":"Aceptado","suspect":"Sospechoso","processing":"En proceso","coin_ready":"Moneda Lista","coin_done":"Moneda Hecha","done":"Hecho","almost_done":"Casi termino","canceled":"Cancelado","failed":"Ha fallado"}},"auth":{"please_active_two_factor":"Primero configure el número de móvil o el autenticador de Google.","submit":"Enviar","otp_placeholder":"Contraseña de 6 dígitos","google_app":"Google Authenticator","sms":"Mensajes de verificación de SMS","send_code":"Enviar código","send_code_alt":"Reenviar en COUNT segundos","hints":{"app":"Google Authenticator volverá a generar una nueva contraseña cada treinta segundos, ingrese a tiempo.","sms":"Le enviaremos un mensaje de texto a su teléfono con el código de verificación."}},"markets":{"market_list":{"all":"Todo el mercado","brl":"BRL Mercado","btc":"BTC Mercado","bch":"BCH Mercado","btg":"BTG Mercado","dash":"DASH Mercado","eth":"ETH Mercado","zec":"ZEC Mercado","dgb":"DGB Mercado","xrp":"XRP Mercado","smart":"Smart Mercado","iota":"IOTA Mercado","ltc":"LTC Mercado","zcr":"ZCR Mercado","tusd":"TUSD Mercado","xem":"XEM Mercado","rbtc":"RBTC Mercado","rif":"RIF Mercado","xar":"XAR Mercado"}},"markets_overview":{"market_depth":"Profundidad del Mercado"}}};
I18n.locale = 'es';


