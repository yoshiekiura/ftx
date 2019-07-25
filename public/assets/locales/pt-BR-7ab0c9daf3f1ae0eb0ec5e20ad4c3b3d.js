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
I18n.translations = {"pt-BR":{"brand":"Cointrade","submit":"Enviar","cancel":"Cancelar","confirm":"Confirmar","continue":"Continuar","banks":{"_065":"Andbank","_654":"Banco A.j. Renner S.A.","_246":"Banco Abc/brasil S.A.","_121":"Banco Agibank S.A.","_025":"Banco Alfa S.A.","_213":"Banco Arbi S.A.","_096":"Banco B3 S.A.","_036":"Banco Bem S.a..","_122":"Banco Berj S.A.","_318":"Banco Bmg Comercial S.A.","_752":"Banco Bnp Paribas Brasil S.A.","_107":"Banco Bocom Bbm S.A.","_069":"Banco Bpn Brasil S.A.","_063":"Banco Bradescard S.A.","_237":"Banco Bradesco S.A.","_218":"Banco Bs2 S.A.","_473":"Banco Caixa Geral Brasil S.A.","_412":"Banco Capital S.A.","_040":"Banco Cargill S.A.","_266":"Banco Cedula S.A.","_745":"Banco Citibank S.A.","_756":"Banco Cooperativo do Brasil S.A.","_748":"Banco Cooperativo Sicredi S.A.","_505":"Banco Credit Suisse (brasil) S.A.","_003":"Banco da Amazonia S.A.","_083":"Banco da China Brasil S.A.","_707":"Banco Daycoval S.A.","_070":"Banco de Brasilia S.A.","_300":"Banco de La Nacion Argentina S.A.","_487":"Banco Deutsche Bank S.A.","_001":"Banco do Brasil S.A.","_047":"Banco do Estado de Sergipe S.A.","_021":"Banco do Estado do Espirito Santo S.A.","_037":"Banco do Estado do Para S.A.","_041":"Banco do Estado do Rio Grande do Sul S.A.","_004":"Banco do Nordeste do Brasil S.A.","_265":"Banco Fator S.A.","_224":"Banco Fibra S.A.","_626":"Banco Ficsa S.A.","_394":"Banco Finasa Bmc S.A.","_612":"Banco Guanabara S.A.","_604":"Banco Industrial do Brasil S.A.","_653":"Banco Indusval S.A.","_077":"Banco Intermedium","_074":"Banco J. Safra S.A.","_376":"Banco Jp Morgan S.A.","_600":"Banco Luso Brasileiro S.A.","_389":"Banco Mercantil do Brasil S.A.","_755":"Banco Merrill Lynch S.A.","_746":"Banco Modal S.A.","_456":"Banco Mufg Brasil S.A.","_079":"Banco Original do Agronegocio S.A.","_212":"Banco Original S.A.","_208":"Banco Pactual S.A.","_623":"Banco Pan","_254":"Banco Parana Banco S.A.","_611":"Banco Paulista S.A.","_643":"Banco Pine S.A.","_747":"Banco Rabobank International Br S.A.","_633":"Banco Rendimento S.A.","_741":"Banco Ribeirao Preto S.A.","_422":"Banco Safra S.A.","_033":"Banco Santander S.A.","_743":"Banco Semear S.A.","_366":"Banco Societe Generale Brasil S.A.","_637":"Banco Sofisa","_243":"Banco Stock Maxima S.A.","_464":"Banco Sumitomo Mitsui Brasileiro S.A.","_634":"Banco Triangulo S.A.","_018":"Banco Tricury S.A.","_655":"Banco Votorantim S.A.","_610":"Banco Vr S.A.","_222":"Bco Credit Agricole Brasil S.A.","_017":"Bny Mellon Banco S.A.","_125":"Brasil Plural S.A.","_097":"Cc Centralcredi","_136":"Cc Unicred do Brasil","_320":"Ccb Brasil","_098":"Cerdialinca Cooperativa Credito Rural","_739":"Cetelem","_163":"Commerzbank","_085":"Cooperativa Central de Credito / Ailos","_099":"Cooperativa Central Econ. Cred. Mutuo Un","_089":"Cooperativa de Credito Rural da Regiao D","_010":"Credicoamo Credito Rural Cooperativa","_104":"Cx Economica Federal","_094":"Finaxis","_132":"Icbc do Brasil Banco Multiplo S.A.","_630":"Intercap","_341":"Itaú Unibanco S.A.","_076":"Kdb do Brasil","_757":"Keb Hana do Brasil","_753":"Nbc Bank Brasil Sa/banco Multiplo","_260":"Nu Pagamentos S.A.","_613":"Omni Banco S A","_120":"Rodobens","_751":"Scotiabank Brasil S.a. Banco Multiplo","_082":"Topazio","_084":"Uniprime Norte do Parana Cc","_119":"Western Union","_124":"Woori Bank"},"fund_sources":{"manage_bank_account":"Cadastro de contas favoritas","manage_bank_account_desc":"Por favor, cadastre aqui as contas bancárias que serão utilizadas para depósitos e saques em Reais.","manage_bank_account_alert_deposit":"Por favor, cadastre aqui as contas bancárias que serão utilizadas para depósitos em Reais, assim como é indispensável informar o seu CPF.","manage_bank_account_alert_withdraw":"Por favor, cadastre aqui as contas bancárias que serão utilizadas para saques em Reais, assim como é indispensável informar o seu CPF.","manage_bank_account_info":"*Atenção Caso o dígito do seu banco for X, favor substituir por 0.","manage_bank_account_required":"Todos os campos são obrigatórios.","copied":"Copiado!","msg_time_close":"Horário para depósito: 09:00-16:30, exceto conta Itaú(TEF)","manage_coin_address":"Cadastro de carteiras favoritas","manage_coin_address_desc":"Por favor, cadastre aqui o endereço de suas carteiras favoritas para o resgate da criptomoeda.","type_deposit":"Tipo de depósito","type_transfer":"Tipo de transferência","fiat":"REAIS","region":"País","bank_transfer":"Transferência","bank_slip":"Boleto","select_region":"Selecione o país","brasil":"Brasil","select_type":"Selecione o tipo","others":"Outros","value":"Valor","bank":"Banco","select_account":"Selecione a conta","account":"Conta","cpf":"CPF/CNPJ","label_agency":"Agência (sem dígito)","agency":"Agência","label_account-dig":"Dígito da conta","account-dig":"Dígito","digit":"Díg.","label":"Apelido","address":"Endereço","action":"Ação","add":"Adicionar","remove":"Remover","default":"Padrão"},"payment_slip":{"bank":"Banco","label_name":"Nome","label_cpf":"CPF","label_cnpj":"CNPJ","label_cpfcnpj":"CPF ou CNPJ","label_phone":"Num.Celular","label_email":"E-mail","label_address":"Endereço Completo","label_city":"Cidade","label_uf":"UF","label_state":"Estado","label_cep":"CEP","label_complement":"Complemento","label_number":"Número","title":"Geração do Boleto","label":"Apelido","address":"Endereço","action":"Ação","add":"Adicionar","remove":"Remover","default":"Padrão","desc":"Os dados aqui informados serão utilizados na geração do boleto.","btn_generete_slip":"Gerar Boleto","label_amount":"R$ 00000","value_req":"Todos os campos obrigatórios","label_tabDeposit":"Depósitos","label_tabBank":"Boleto Bancário","amount":"Valor","amount_total":"Valor Total","tax":"Taxa","tax_percent":"Percentual de 0.0% e mais a taxa de R$ 6,50 para o provedor do boleto!","incomplete_form":"Dados incompletos!","click_slip":"Clique para imprimir o boleto"},"funds":{"deposit":"Depósito","withdraw":"Resgate","tooltip_status":{"accepted":{"text":"O depósito foi processado com êxito. Favor verificar em sua carteira pessoal.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"checked":{"text":"Ordem revisada pelo Admin.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"submitting":{"text":"A ordem de depósito está sendo submetida.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitted":{"text":"A ordem de depósito foi submetida.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"cancelled":{"text":"Ordem rejeitada.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"rejected":{"text":"Ordem rejeitada.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"warning":{"text":"Nenhuma transação foi processada até o momento. Por favor, contate o nosso suporte.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"},"suspect":{"text":"Ordem irregular. Por favor, contate o nosso suporte.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"}},"deposit_modal":{"tef":"TEF (Transferência entre contas Itaú)","ted":"TED (Transferência Eletrônica Disponível)","dia":"DIA (Depósito em dinheiro Identificado na agência)","session_expire":"Tempo expirado, ordem de depósito cancelada automáticamente.","deposit_code":"Código para identificação do depósito","content_header":" \u003Ctable width=\"100%\" style=\"background:#28363D;\"\u003E \u003Ctbody\u003E \u003Ctr align=\"center\"\u003E \u003Ctd style=\"padding:10px 10px 10px 10px; display:flex; justify-content: center; align-items:center;\"\u003E \u003Cimg  src=\"logo_cx_email.png\" \u003E \u003C/td\u003E \u003C/tr\u003E \u003C/tbody\u003E \u003C/table\u003E \u003Cdiv style=\"padding-left:35px;padding-right:35px;padding-top:10px;\"\u003E \u003Cspan style=\"font-size:30px;\"\u003EATENÇÃO! Informações de como realizar um depósito.\u003C/span\u003E\u003Cbr\u003E \u003Cspan style=\"font-size:20px;\"\u003ESua ordem de %{type_transfer_description} de Reais foi criada no sistema.\u003C/span\u003E \u003C/div\u003E","content_tef":"    \u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; color:white; background-color:#EA5E6E;\"\u003E \u003Cspan style=\"font-size:20px;\"\u003EVALOR DE DEPÓSITO: \u003Cspan style=\"font-size:30px;\"\u003ER$ %{valor_deposito}\u003C/span\u003E\u003C/span\u003E\u003Cbr\u003E \u003C/span\u003E \u003C/div\u003E\n\u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; font-weight:bold; color:grey\"\u003E Dados bancários para transferência:\u003C/br\u003E Banco: 341 - Itaú\u003C/br\u003E Agência: 7307\u003C/br\u003E Conta: 08782-0\u003C/br\u003E COINBR SERVICOS DIGITAIS LTDA\u003C/br\u003E CNPJ: 11.768.654/0001-86\u003C/br\u003E Data: %{date_create}\u003C/br\u003E Hora: %{time_created}\u003C/br\u003E \u003Cdiv\u003E \u003Cbr\u003E","content_ted":" \u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; color:white; background-color:#EA5E6E;\"\u003E \u003Cspan style=\"font-size:20px;\"\u003EVALOR DE DEPÓSITO: \u003Cspan style=\"font-size:30px;\"\u003ER$ %{valor_deposito}\u003C/span\u003E\u003C/span\u003E\u003Cbr\u003E \u003Cspan\u003E\u003Cspan style=\"font-weight:bold\"\u003E*ATENÇÃO\u003C/span\u003E: Fazer o depóstio de acordo com o valor exato informado acima.\u003Cbr\u003E \u003Cspan style=\"font-size:20px;\"\u003EData de vencimento: %{expire}\u003Cspan\u003E \u003C/span\u003E \u003C/div\u003E\n\n\u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; font-weight:bold; color:grey\"\u003E Dados bancários para transferência:\u003C/br\u003E CPF: %{samurai_code}\u003C/br\u003E Banco: 341 - Itaú\u003C/br\u003E Agência: 7307\u003C/br\u003E Conta: 08782-0\u003C/br\u003E COINBR SERVICOS DIGITAIS LTDA\u003C/br\u003E CNPJ: 11.768.654/0001-86\u003C/br\u003E \u003C/br\u003E Data: %{date_create}\u003C/br\u003E Hora: %{time_created}\u003C/br\u003E \u003C/div\u003E ","content_footer_tef":"\u003Cdiv\u003E*Os valores para transferência mínimo de R$ 25,00 (vinte e cinco reais). Transferências efetuadas que estejam abaixo de R$ 25,00 (vinte e cinco reais) não serão compensadas, e serão devolvidas mediante pagamento de taxa de R$20,00 (vinte reais).\u003Cbr\u003E\nOs valores de depósitos BRL (em Reais) realizados em toda nossa plataforma terminam com 08 centavos para possibilitar o processo de verificação automática,garanta que o valor depositado inclua os 08 centavos requisitados para o mesmo ser corretamente identificado.\u003Cbr\u003E\nA confirmação do depósito poderá levar até 3 dias úteis, porém, o tempo médio atual é de até 3 horas.\u003C/div\u003E","content_footer_ted":"\u003Cdiv style=\"width:100%;padding-bottom:15px;padding-left:35px;padding-right:35px; font-weight:bold; color:grey; font-size:13px\"\u003E\u003Cspan style=\"color:#EA5E6E;\"\u003E*Os valores de depósitos BRL (em Reais) realizados em toda nossa plataforma terminam com 08 centavos para possibilitar o processo de verificação automática, garanta que o valor depositado inclua os 08 centavos requisitados para o mesmo ser corretamente identificado.\u003C/span\u003E\u003Cbr\u003E A confirmação do depósito poderá levar até 3 dias úteis, porém, o tempo médio atual é de até 6 horas.\u003C/span\u003E\u003C/div\u003E "},"currency_name":{"btc":"BTC","brl":"BRL","doge":"DOGE","pts":"PTS","ltc":"LTC","bhc":"BHC","btg":"BTG","dash":"DASH","eth":"ETH","zec":"ZEC","dgb":"DGB","xrp":"XRP","smart":"Smart","iota":"IOTA","zcr":"ZCR","tusd":"TUSD","xem":"XEM","rbtc":"RBTC","rif":"RIF","xar":"XAR"},"deposit_brl":{"title":"No seu banco","title2":"No seu banco","title_transfer":"Depósito via Transferência Bancária","title_slip":"Depósito via Boleto Bancário","desc":"Siga os passos abaixo:","desc1":null,"message_validation2":"Não foi possível conectar ao provedor de Boleto !","desc_item_1":"Informe o valor do depósito;","desc_item_2":"Acesse a opção CADASTRAR CONTAS e cadastre a sua conta bancária;","desc_item_3":"Clique no botão Enviar;","desc_item_4":"Informações sobre o procedimento serão exibidas na tela e enviadas por e-mail.","desc_item_5":"Transfira o dinheiro para a conta da COINBR SERVICOS DIGITAIS LTDA;","desc_item_6":"Valor mínimo de R$25,08 com identificação do CPF;","desc_item_7":"SEMPRE envie o seu comprovante de depósito para \u003Ccomprovante@cointrade.cx\u003E. Seu depósito será confirmado assim que seu dinheiro for recebido.","desc_item_8":"Horário para depósito: 09:00 às 16:30. Todo o TED que for gerado no dia e não for executado no mesmo até as 16:30h será rejeitado, gerando uma cobrança de R$ 20,00 pelo estorno.","attention":"Atenção NÃO aceitamos transferências de outro titular, sujeito a estorno e multa de R$ 20,00 sobre o valor. O nome do seu banco deve ser o mesmo do cadastrado em sua conta em nosso site, caso contrário seu depósito não será corretamente identificado.","attention2":"Os valores de depósitos (em Reais) realizados em toda nossa plataforma terminam com 08 centavos para possibilitar o processo de verificação automática.","observations_slip":"Observações","desc_on_slip":{"desc_item_1":"Valor mínimo para depósito: R$ 25,00;","desc_item_2":"A empresa processadora do boleto cobra uma taxa de 0.0% mais R$ 6,50;","desc_item_3":"Essa taxa é adicionada ao valor total do boleto gerado, onde a processadora fará o desconto de suas taxas quando o mesmo for compensado."},"bank_information":{"title":"Nossas informações bancárias","label_bank":"Banco","bank":"341 - Itaú","label_recipient":"Beneficiário","recipient":"COINBR SERVICOS DIGITAIS LTDA","label_cnpj":"CNPJ","cnpj":"11.768.654/0001-86","label_agency":"Agência","agency":7307,"label_account":"Conta","account":"08782-0","place_holder_amount":"Valor mínimo 25 Reais"},"from":"De","to":"Para","deposit_name":"Seu nome","deposit_account":"Conta de depósito","add":"Adicionar","manage":"CADASTRAR CONTAS","amount":"VALOR","type":"Tipo","document":"CPF","document_mask":"000.000.000-00","min_amount":"Valor mínimo 25,00 Reais","to_account":"TED/DOC","account_detail":"Itaú Ag: 7307 Conta: 08782-0","to_name":"Razão Social","to_bank_name":"Nome do Banco","opening_bank_name":"CNPJ","remark":"Código Referência (Código de Identificação da Transferência)","label_deposit_ammount":"Valor","label_deposit_value":"Selecione o tipo de transação?","label_deposit_vlr":"Valor do depósito","label_desc":"De qual conta será feito a transação?","deposit_information_title":"ATENÇÃO! Informações de como realizar um depósito.","deposit_warning_title":"ATENÇÃO!! ANOTE O SEU NÚMERO IDENTIFICADOR ABAIXO!","deposit_warning_information":"Para maiores informações, \u003Ca style=\"text-decoration: underline;\" href=\"https://cointrade.zendesk.com/hc/pt-br/articles/360007415133\" target=\"_blank\"\u003Eclique aqui\u003C/a\u003E e acesse nosso manual explicando passo a passo como efetuar a transação no seu banco!\u003C/br\u003E Um E-mail está sendo enviado com este comprovante para a sua caixa postal, qualquer dúvida, por favor consulte seu e-mail. \u003Cbr/\u003EObrigado.","message_error":"Ocorreu um erro, por favor tente novamente mais tarde","message_error_limit":"O valor mínimo do depósito é de 25 reais.","message_validation":"Favor preencher todos os campos","message_creation":"Criado com sucesso","slip_buttom":"Boleto","message_rejected":"Depósito rejeitado, é permitido apenas um depósito do tipo TED com mesmo valor e mesmo CPF por dia."},"deposit_btc":{"title":"BTC Depósito"},"deposit_bch":{"title":"BCH Depósito"},"deposit_btg":{"title":"BTG Depósito"},"deposit_dash":{"title":"DASH Depósito"},"deposit_eth":{"title":"ETH Depósito"},"deposit_zec":{"title":"ZEC Depósito"},"deposit_dgb":{"title":"DGB Depósito"},"deposit_xrp":{"title":"XRP Depósito"},"deposit_smart":{"title":"Smart Depósito"},"deposit_iota":{"title":"IOTA Depósito"},"deposit_ltc":{"title":"LTC Depósito"},"deposit_zcr":{"title":"ZCR Depósito"},"deposit_tusd":{"title":"TUSD Depósito"},"deposit_xem":{"title":"XEM Depósito"},"deposit_rbtc":{"title":"RBTC Depósito"},"deposit_rif":{"title":"RIF Depósito"},"deposit_xar":{"title":"XAR Depósito"},"deposit_coin":{"address":"Endereço","copy":"Copiar","new_address":"Novo Endereço","confirm_gen_new_address":"Tem certeza que deseja gerar um novo endereço para depósito ?","open-wallet":"Por favor use seu serviço de carteira BTC, Carteira Local, Carteira Mobile or Carteira Online, Selecione enviar pagamento e Envie.","detail":"Por favor cole o endereço abaixo em sua carteira, e preencha o valor que deseja depositar, então confirme e Envie.","scan-qr":"Leia o QR code para efetuar o pagamento usando sua carteira mobile.","after_deposit":"Assim que completar o envio, você poderá checar o status do seu depósito abaixo.","generate-new":"Gerar novo Endereço","tag_xrp_tip":"*Para realizar um depósito de XRP é necessário o uso da TAG,","tag_xrp_tip_2":"caso contrário o seu depósito será perdido.","txidText":"Após gerar o seu deposito, é necessário inserir aqui o Txid (transaction ID)","txidText2":"gerado através da plataforma de sua preferência. Para consultar os seus depósitos,","click":"clique aqui!","insertTxid":"Insira o seu Txid","msg1":"Seu TXID foi salvo com sucesso e iremos investigá-lo para creditar o seu depósito o quanto antes.","msg2":"Você já tem ordem de depósito com esse número de Txid."},"deposit_history":{"fiat":"REAIS","title":"HISTÓRICO","describe":"Todos os endereços de depósitos de cryptos foram atualizados.","describe1":"Antes de efetuar um novo depósito em crypto na plataforma,","describe2":"certifique-se de estar utilizando o endereço correto.","describe3":"Todos os endereços de depósitos de criptos foram atualizados.\u003Cbr/\u003E Antes de efetuar um novo depósito em cripto na plataforma,\u003Cbr/\u003E certifique-se de estar utilizando o endereço correto.","number":"#","identification":"Identificação","time":"Horário","txid":"ID da Transação","transaction_type":"Tipo de Transação","inserted_txid":"Txid Inserido","slip_type":"Boleto","coin":"Moeda","confirmations":"Confirmações","from":"De","imformation_from":"Informações da transação","amount":"Valor","state_and_action":"Status/Ação","cancel":"cancelar","no_data":"Não há dados históricos","validator":"Validador","submitting":"Submetendo","cancelled":"Cancelado","submitted":"Submetido","accepted":"Aceito","rejected":"Rejeitado","checked":"Checado","warning":"Alerta","suspect":"Suspeito"},"withdraw_brl":{"title":"Saque em Reais","desc":"Siga os passos abaixo:","intro":"Selecione o banco para saque do valor e entre com o número da conta corrente para completar o envio.","intro_2":"Horário para saque: 09:00 às 16:30. Todo o TED que for gerado no dia e não for executado no mesmo até as 16:30h será rejeitado, gerando uma cobrança de R$ 20,00 pelo estorno.","intro_3":"Se a sua conta cadastrada para saque for do banco Itaú, não será cobrada nenhuma taxa de transação. Caso você queira realizar o saque para uma conta que não seja do banco Itaú, será cobrada a taxa de TED no valor de R$10,90.","intro_4":"Para sacar acima de 5 (cinco) BTCs é necessária a autorização da equipe Cointrade.","intro_5":"Para saques em BRL será cobrado uma taxa de 0.25% sobre o valor sacado.","intro_6":"Caso você queira realizar o resgate para uma conta que não seja do banco Itaú, será cobrada a taxa de TED no valor de R$10,90.","intro_7":"Horário para saque: 09:00 às 16:30 horario brasileiro. Todo o ted que for gerado no dia e não for executado no mesmo até as 16:30h será rejeitado, gerando uma cobrança de R$ 20,00 pelo estorno.","attention":"Horário Comercial: 9:00 - 18:00","account_name":"Nome da Conta","withdraw_address":"Conta destino","balance":"Valor disponível","balance_tip":"Valor disponivel para saque","locked":"Valor em negociação","locked_tip":"Valor bloqueado por estar com ordens de trade em aberto","total":"Valor total","total_tip":"Soma do valor disponível com os valores bloqueados\u003Cbr\u003E de trades em aberto","withdraw_amount":"Valor de Resgate (R$)","manage_withdraw":"Contas favoritas","fee_explain":"Sobre as taxas","min":"No mínimo","withdraw_all":"Sacar tudo","message_success":"Saque submetido"},"withdraw_btc":{"title":"BTC Resgate"},"withdraw_bch":{"title":"BCH Resgate"},"withdraw_btg":{"title":"BTG Resgate"},"withdraw_dash":{"title":"DASH Resgate"},"withdraw_eth":{"title":"ETH Resgate"},"withdraw_zec":{"title":"ZEC Resgate"},"withdraw_dgb":{"title":"DGB Resgate"},"withdraw_xrp":{"title":"XRP Resgate"},"withdraw_smart":{"title":"Smart Resgate"},"withdraw_iota":{"title":"IOTA Resgate"},"withdraw_ltc":{"title":"LTC Resgate"},"withdraw_zcr":{"title":"ZCR Resgate"},"withdraw_tusd":{"title":"TUSD Resgate"},"withdraw_xem":{"title":"XEM Resgate"},"withdraw_rbtc":{"title":"RBTC Resgate"},"withdraw_rif":{"title":"RIF Resgate"},"withdraw_xar":{"title":"XAR Resgate"},"withdraw_coin":{"intro":"Por favor preencha o endereço e a quantia, então submeta o formulário.","label":"Apelido","balance":"BTC disponível","amount":"Quantidade saque","manage_withdraw":"Endereços favoritos","min":"no mínimo","withdraw_all":"Sacar tudo","fee_explain":"Sobre as taxas","with":"Valor da taxa para saque"},"withdraw_history":{"title":"Histórico de Resgates","number":"Identificação","withdraw_time":"Horário","coin":"Moeda","withdraw_account":"Conta de Saque","withdraw_address":"Endereço","withdraw_amount":"Valor","actual_amount":"Valor Atual","fee":"Taxa","fee_ted":"Taxa TED","fee_withdraw":"Taxa Saque","miner_fee":"Taxa","state_and_action":"Status/Ação","cancel":"Cancelar","no_data":"Não há dados históricos","inserted_txid":"Txid fornecido pela Stratum","submitting":"Submetendo","submitted":"Submetido","rejected":"Rejeitado","accepted":"Aceito","suspect":"Suspeito","warning":"Alerta","checked":"Checado","cancelled":"Cancelado","processing":"Processando","coin_ready":"Moeda Pronto","coin_done":"Moeda Feito","done":"Feito","almost_done":"Em Andamento","canceled":"Cancelado","failed":"Falhou","validator":"Validador","value":"10,90","value_percent":"0,25%","fee_info":"Saque em BRL: Taxa de 0.25% sobre o valor sacado + o valor de TED R$10,90.\u003Cbr\u003E *Para TEF (entre contas Itaú) não é cobrado TED.\u003Cbr\u003E Saque em Crypto: Taxa do valor de rede da crypto sacada.","tooltip_status":{"accepted":{"text":"O saque foi processado com êxito. Favor verificar em sua carteira pessoal.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"done":{"text":"O saque foi processado com êxito. Favor verificar em sua carteira pessoal.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"checked":{"text":"Ordem revisada pelo Admin.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"almost_done":{"text":"A ordem de saque está sendo submetida.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitting":{"text":"A ordem de saque está sendo submetida.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitted":{"text":"A ordem de saque foi submetida.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"cancelled":{"text":"Ordem rejeitada.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"rejected":{"text":"Ordem rejeitada.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"warning":{"text":"Nenhuma transação foi processada até o momento. Por favor, contate o nosso suporte.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"},"suspect":{"text":"Ordem irregular. Por favor, contate o nosso suporte.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"},"processing":{"text":"A ordem de saque está sendo processada.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"}}}},"auth":{"please_active_two_factor":"Por favor informe seu telefone celular ou ative a autenticação de 2 fatores (use google authenticator).","submit":"Submeter","otp_placeholder":"Senha de 6 dígitos","google_app":"Google Authenticator","sms":"SMS Mensagem de Verificação","send_code":"Enviar Código","send_code_alt":"Reenviar em COUNT Segundos","hints":{"app":"Google Authenticator irá regerar uma nova senha a cada 30 segundos, Entre em tempo.","sms":"Enviaremos uma mensagem de texto para seu telefone com um código de verificação."},"term_agree":"TERMOS DE SERVIÇO\u003Cbr\u003E 1. O presente Termo de Serviços estabelece as condições de uso da Plataforma entre a Cointrade Crypto Exchange e seus Usuários.\u003Cbr\u003E 2. A Cointrade Crypto Exchange não compra e vende moedas. O objetivo da Plataforma é aproximar usuários para a compra e venda de suas próprias criptomoedas oferecendo funcionalidades para facilitar as transações.\u003Cbr\u003E 3. Para transacionar na Plataforma Cointrade Crypto Exchange você deve cadastrar-se, bastando para isso informar um e-mail válido e senha, momento em que você declara e reconhece que leu, entendeu e aceitou irrevogavelmente este Termo de Uso seus anexos e/ou apêndices, bem como documentações e informações publicadas no site.\u003Cbr\u003E 4. Este Termo de Serviço, seus anexos, apêndices, serviços, ferramentas e condições podem ser alterados, emendados, modificados, eliminados ou atualizados pela Cointrade Crypto Exchange a qualquer momento e sem aviso prévio. Razão pela qual, você deve verificar com frequência para confirmar se sua cópia e o entendimento desse Termo de Uso, anexos e apêndices estão atualizados e corretos. A não rescisão ou o uso de quaisquer serviços após a data efetiva de quaisquer incorporações, alterações, modificações ou atualizações constitui implícita e inequivocamente sua aceitação das modificações por tais emendas, alterações ou atualizações. Se você não concordar com quaisquer termos aqui dispostos não cadastre-se e ou não dê continuidade de uso do site cointrade.cx.\u003Cbr\u003E 5. O uso do site e de quaisquer serviços é nulo onde for proibido pela lei aplicável.\u003Cbr\u003E 6. Neste ato o usuário declara e garante que\u003Cbr\u003E 6.1. Tem no mínimo 18 anos completos, capacidade civil plena, de acordo com a sua jurisdição relevante;\u003Cbr\u003E 6.2. Não ter sido previamente suspenso ou removido de nossos serviços;\u003Cbr\u003E 6.3. Ter plenos poderes e autoridade para entrar nesta relação jurídica e, ao fazê-lo, não violará quaisquer outras relações jurídicas;\u003Cbr\u003E 6.4. Usa nossa Plataforma com seu próprio e-mail;\u003Cbr\u003E 6.5. Os ativos de criptografia que transfere para a plataforma não estão vendidos, onerados, em disputa ou sob apreensão, e que não existe nenhum direito de terceiros sobre eles;\u003Cbr\u003E 6.6. Cessará imediatamente de utilizar nossos serviços se em qualquer época for residente ou se tornar residente de estado ou região, onde as transações de ativos de criptografia forem proibidos ou passarem a exigir aprovação especial, permissão ou autorização de qualquer tipo, que a Cointrade Crypto Exchange não tenha obtido;\u003Cbr\u003E 6.7. Concorda que não violará nenhuma lei, contrato, propriedade intelectual ou outro direito de terceiros ou cometerá um ato ilícito e que é o único responsável por sua conduta ao usar nossa Plataforma.\u003Cbr\u003E 7. Sem prejuízo da generalidade do exposto, você declara, concorda, aceita e garante  que não irá.\u003Cbr\u003E 7.1. Utilizar a Plataforma de qualquer maneira que possa interferir, perturbar, afetar negativamente ou inibir outros usuários de usar nossa Plataforma com funcionalidade completa, ou que possa danificar, desabilitar, sobrecarregar ou prejudicar o funcionamento da Plataforma de qualquer maneira;\u003Cbr\u003E 7.2. Utilizar a Plataforma para pagar, apoiar ou, de alguma forma, participar de quaisquer atividades ilegais de jogos de azar; fraude; lavagem de dinheiro; ou atividades terroristas; ou quaisquer outras atividades ilegais;\u003Cbr\u003E 7.3. Utilizar qualquer robô, aranha, rastreador, scraper ou outro meio automatizado ou interface não fornecida pela Cointrade Crypto Exchange para extrair dados;\u003Cbr\u003E 7.4. Usar ou tentar usar outra conta de usuário sem autorização;\u003Cbr\u003E 7.5. Tentar burlar quaisquer técnicas de filtragem de conteúdo que a Cointrade Crypto Exchange utilize, ou tentar acessar qualquer serviço ou área da Plataforma que não esteja autorizado a acessar;\u003Cbr\u003E 7.6. Desenvolver quaisquer aplicativos de terceiros que interajam com a Plataforma sem o consentimento prévio por escrito da Cointrade Crypto Exchange.\u003Cbr\u003E DOS RISCOS\u003Cbr\u003E 8. Você reconhece e concorda que usará a Plataforma por sua conta e risco. O risco de perda na negociação de ativos criptográficos pode ser substancial, desta forma, você deve considerar se essa negociação é apropriada para você. Não há garantia contra perdas no Site.\u003Cbr\u003E 8.1 Você reconhece e concorda com a possibilidade do seguinte;\u003Cbr\u003E 8.1.a Você pode suportar uma perda total dos cripto ativos na sua conta Cointrade Crypto Exchange.\u003Cbr\u003E 8.1.b Sob certas condições de mercado, você pode ter dificuldade de liquidar uma posição, como por exemplo, quando a liquidez no mercado for insuficiente por ter atingido um limite diário de oscilação de preço (\"movimento limite\").\u003Cbr\u003E 8.1.c A utilização de ordens como, \"stop-loss\" ou \"stop-limit\", não limitará necessariamente suas perdas aos valores pretendidos, uma vez que as condições do mercado podem impossibilitar a execução de tais ordens.\u003Cbr\u003E 8.1.d Os pontos mencionados acima se aplicam a todos os ativos criptografados. Esta breve declaração não pode, no entanto, expor todos os riscos e outros aspectos associados ao comércio de ativos criptográficos e não deve ser considerada como qualquer aconselhamento profissional.\u003Cbr\u003E 8.2. Você reconhece que existem riscos associados à utilização de um sistema de comércio baseado na Internet, incluindo, mas não se limitando a, falhas de hardware, software e conexões com a Internet. Você reconhece que a Cointrade Crypto Exchange não será responsável por quaisquer falhas de comunicação, interrupções, erros, distorções ou atrasos que você possa ter ao usar a Plataforma, independentemente da causa.\u003Cbr\u003E 8.3. A Plataforma e seus Serviços relacionados são baseados no protocolo Blockchain, assim, qualquer mau funcionamento, função não intencional, funcionamento inesperado ou ataque ao protocolo Blockchain pode causar mau funcionamento ou funcionamento da Plataforma de forma inesperada ou não intencional.\u003Cbr\u003E 8.4. Você reconhece e aceita que o Cointrade Crypto Exchange não tem controle sobre nenhuma rede de criptografia e compreende todos os riscos associados à utilização de qualquer rede de ativos de criptografia, e que a Cointrade Crypto Exchange não é responsável por qualquer dano que ocorra como resultado de tais riscos.\u003Cbr\u003E 8.5. Você é totalmente responsável por proteger seu acesso à Plataforma Tecnológica, sua chave privada, senhas e detalhes da sua conta bancária.\u003Cbr\u003E DA PROTEÇÃO DOS CRYPTO ATIVOS\u003Cbr\u003E 9. Nós nos esforçamos para proteger seus ativos de criptografia, e para tanto, utilizamos uma variedade de medidas físicas e técnicas projetadas para proteger nossos sistemas e seus ativos de criptografia. Ao remeter seus ativos de criptografia para a Conta Cointrade Crypto Exchange, você nos confia e nos autoriza a tomar decisões sobre a segurança de seus ativos de criptografia.\u003Cbr\u003E DAS NOTIFICAÇÕES\u003Cbr\u003E 10. Você concorda e consente em receber eletronicamente todas as Comunicações, que a Cointrade Crypto Exchange esteja disposta a fazer. Você concorda que a Cointrade Crypto Exchange pode fazer essas Comunicações publicando-as na Plataforma.\u003Cbr\u003E 10.1. É de sua total responsabilidade manter o seu endereço de e-mail registrado na Cointrade Crypto Exchange atualizado para que possamos nos comunicar com você eletronicamente. Você entende e concorda que, se a Cointrade Crypto Exchange lhe enviar uma comunicação eletrônica, mas você não a receber porque seu endereço de email está incorreto, desatualizado, bloqueado por seu provedor de serviços ou se você não puder receber comunicações eletrônicas, a Cointrade Crypto Exchange irá considerar como realizada a comunicação. Você renuncia ao seu direito de alegar ignorância.\u003Cbr\u003E 10.2. Se você usar um filtro de spam que bloqueia ou redireciona e-mails de remetentes não cadastrados em sua lista de contatos, você deve adicionar a Cointrade Crypto Exchange para que possa receber as Comunicações.\u003Cbr\u003E 10.3. Se as correspondências eletrônicas enviadas a você pela Cointrade Crypto Exchange retornarem, a Cointrade Crypto Exchange poderá considerar que sua conta está inativa, e você poderá não conseguir concluir qualquer transação através da Plataforma até recebermos de você um endereço de e-mail válido.\u003Cbr\u003E 10.4. Se você não tiver feito login em sua conta no site por um período ininterrupto de dois anos, a Cointrade Crypto Exchange reserva-se o direito de considerar que toda e qualquer propriedade que você detenha no site está abandonada, e poderá ser imediatamente perdida e confiscada pela Cointrade Crypto Exchange.\u003Cbr\u003E 10.5. Qualquer benefício concedido a qualquer usuário da Cointrade Crypto Exchange, será considerada como mera liberalidade por parte desta, e não deverá afetar aos demais usuários da Cointrade Crypto Exchange.\u003Cbr\u003E CONDIÇÕES ESPECIAIS\u003Cbr\u003E 11. A qualquer momento e a nosso exclusivo critério, podemos impor limites ao valor da Transferência permitida pela Plataforma ou impor quaisquer outras condições ou restrições ao uso da Plataforma sem prévio aviso.\u003Cbr\u003E 12. Podemos, a nosso exclusivo critério, sem o aceite do usuário, com ou sem aviso prévio e a qualquer momento, modificar ou descontinuar, temporária ou permanentemente, qualquer parte de nossos Serviços.\u003Cbr\u003E 13. Você só pode cancelar uma solicitação de Transferência já iniciada por meio da Plataforma se tal cancelamento ocorrer antes que a Cointrade Crypto Exchange execute a Transferência. Uma vez que sua solicitação de transferência tenha sido executada, você não poderá alterar, retirar ou cancelar sua autorização. Se uma ordem de negociação foi parcialmente completada, você pode cancelar o restante não completado, a menos que o pedido esteja relacionado a uma taxa de mercado. Reservamo-nos o direito de recusar qualquer pedido de cancelamento associado à taxa de mercado de uma ordem de negociação depois de ter enviado tal pedido. Embora possamos, a nosso exclusivo critério, reverter uma negociação sob certas condições extraordinárias, o usuário não tem direito à reversão de qualquer negociação.\u003Cbr\u003E 14. Se você tiver uma quantidade insuficiente de ativos criptográficos na sua conta Cointrade Crypto Exchange para concluir uma transferência através da plataforma tecnológica, poderemos cancelar todo o pedido ou cumprir um pedido parcial usando a quantidade de ativos criptográficos atualmente disponíveis na sua conta Cointrade Crypto Exchange, menos quaisquer taxas devido à Cointrade Crypto Exchange em decorrência da nossa execução das Transferências.\u003Cbr\u003E 15. É de sua inteira responsabilidade verificar quais impostos, se houver algum, se aplicam às Transferências que você conclui por meio da Plataforma e é sua responsabilidade informar e remeter o imposto correto à autoridade fiscal apropriada. Você concorda que a Cointrade Crypto Exchange não é responsável por determinar se os impostos se aplicam às suas transferências ou por coletar, relatar, reter ou remeter quaisquer impostos decorrentes de quaisquer Transações e Transferências e não atua como seu agente fiscal.\u003Cbr\u003E 16. A Cointrade Crypto Exchange possui direitos exclusivos, incluindo todos os direitos de propriedade intelectual sobre Comentários. Qualquer Feedback que você enviar não é confidencial e se tornará propriedade exclusiva da Cointrade Crypto Exchange. Nós teremos o direito ao uso irrestrito e divulgação de tal Feedback para qualquer propósito, comercial ou outro, sem reconhecimento ou compensação à você. Você renuncia a quaisquer direitos que possa ter sobre o Feedback. Não faça Comentários se você espera ser pago ou deseja continuar a possuir ou reivindicar direitos sobre ele; sua ideia pode ser ótima, mas talvez já tenhamos tido a mesma ideia ou uma ideia semelhante e não queremos disputas. Também temos o direito de divulgar sua identidade a qualquer terceiro que esteja alegando que o conteúdo postado por você constitui uma violação de seus direitos de propriedade intelectual ou de seu direito à privacidade. Temos o direito de remover qualquer postagem que você faça em nosso site se, em nossa opinião, não estiver em conformidade com os padrões de conteúdo nele estabelecidos.\u003Cbr\u003E SUSPENSÃO OU TERMINAÇÃO DA SUA CONTA COINTRADE CRYPTO EXCHANGE\u003Cbr\u003E 17. Em caso de violação dos Termos ou qualquer outro evento que considerarmos necessário, incluindo, sem limitação, perturbação do mercado e/ou evento de Força Maior, poderemos, a nosso exclusivo critério e sem o seu aceite, com ou sem aviso prévio\u003Cbr\u003E 17.1. suspender seu acesso a todos, ou parte de nossos Serviços; ou\u003Cbr\u003E 17.2. impedir que você conclua quaisquer ações por meio da Plataforma, incluindo o fechamento de qualquer ordem de negociação aberta. Caso a transferência seja retomada, você reconhece que as taxas de mercado vigentes podem diferir significativamente das taxas disponíveis antes de tal evento; ou\u003Cbr\u003E 17.3. encerrar seu acesso aos Serviços, excluir ou desativar sua Conta Cointrade Crypto Exchange e todas as informações e arquivos relacionados nessa conta.\u003Cbr\u003E 18. No caso de rescisão, a Cointrade Crypto Exchange retornará quaisquer ativos criptográficos armazenados na sua conta na plataforma, descontados os valores devidos à Cointrade Crypto Exchange, a menos que você tenha cometido fraude, negligência ou outra conduta imprópria.\u003Cbr\u003E GARANTIAS E RESPONSABILIDADES\u003Cbr\u003E 19. Você renuncia a todas as garantias de qualquer tipo, expressas ou implícitas, incluindo as informações, conteúdo e materiais contidos em nossos serviços.\u003Cbr\u003E 20. Você reconhece que as informações que você armazena ou transfere através de nossos serviços podem ser perdidas, corrompidas ou se tornar temporariamente indisponíveis devido a várias causas, incluindo falhas de software, alterações de protocolo por terceiros, interrupções de internet, evento de força maior ou outros desastres, manutenção programada ou não programada ou outras causas dentro ou fora de nosso controle.\u003Cbr\u003E 21. Exceto se exigido por lei, em hipótese alguma, a Cointrade Crypto Exchange, seus diretores, empregados ou agentes serão responsáveis por quaisquer danos diretos ou indiretos de qualquer tipo, incluindo, perda de uso, perda de lucros ou perda de dados, relacionado com o uso ou a incapacidade de usar os nossos serviços ou o IP da Cointrade Crypto Exchange, incluindo quaisquer danos causados pela confiança de qualquer usuário por qualquer informação obtida pela Cointrade Crypto Exchange ou decorrentes de erros, omissões, interrupções, exclusão de arquivos ou e-mails, erros, defeitos, vírus, atrasos em operação ou transmissão ou qualquer falha de desempenho, resultante ou não de um evento de força maior, falha de comunicações, roubo, destruição ou acesso não autorizado aos registros, programas ou serviços da Cointrade Crypto Exchange.\u003Cbr\u003E 22. A Cointrade Crypto Exchange não será responsável por\u003Cbr\u003E 22.1. qualquer imprecisão, erro, atraso ou omissão de qualquer informação, bem como a transmissão ou entrega de informações;\u003Cbr\u003E 22.2. qualquer perda ou dano resultante de um Evento de Força Maior.\u003Cbr\u003E 23. Nós nos esforçamos para proteger nossos usuários de atividades fraudulentas e esquemas na esfera de ativos de criptografia. É possível que alguns ativos criptográficos tenham a finalidade de confiscar ilegalmente a propriedade ou sejam considerados fraude, esquemas ou qualquer outra atividade, reconhecidos pelas leis como ilegais e / ou incompatíveis com os requisitos legais. Reservamo-nos o direito de proibir e descontinuar quaisquer transações em nossa Plataforma com esse recurso de criptografia a nosso exclusivo critério, sem qualquer aviso prévio a você e sem a publicação do motivo de tal decisão, sempre que isso chegar ao nosso conhecimento.\u003Cbr\u003E 24. Seguimos as melhores práticas para decidir se o ativo de criptografia é seguro ou não. No entanto, não damos nenhuma garantia e/ou investimento, financeiro, legal ou qualquer outro conselho profissional, afirmando que qualquer ativo de criptografia disponível através da nossa Plataforma seja seguro.\u003Cbr\u003E DIVERSOS\u003Cbr\u003E 25. No caso de qualquer conflito entre estes Termos e qualquer outro contrato que você possa ter com a Cointrade Crypto Exchange, estes termos prevalecerão, a não ser que tenham sido expressamente identificados e declarados como cancelados pelo outro contrato.\u003Cbr\u003E 26. Reservamo-nos o direito de fazer alterações ou modificações a estes Termos de tempos em tempos, a nosso exclusivo critério, oportunidade em que forneceremos avisos sobre tais alterações, seja por e-mail, ou por aviso na página inicial do Site. Os Termos alterados serão considerados efetivos imediatamente após o Usuário continuar a usar nossos Serviços depois que a Cointrade Crypto Exchange avisar sobre tais mudanças ou publicar nova versão dos Termos no Site.\u003Cbr\u003E 27. Quaisquer Termos alterados serão aplicados aos Serviços após entrarem em vigor. Se você não concordar com quaisquer Termos alterados, você deve interromper o uso de nossos Serviços e entrar em contato conosco para encerrar sua conta.\u003Cbr\u003E 28. Nossa falha ou atraso no exercício de qualquer direito, poder ou privilégio sob estes Termos não deve funcionar como uma renúncia do mesmo.\u003Cbr\u003E 29. A invalidade ou ineficácia de qualquer disposição contida neste Termos não afetará a validade ou exequibilidade das demais, as quais permanecerão em pleno vigor e efeito.\u003Cbr\u003E 30. Você não pode ceder ou transferir quaisquer de seus direitos ou obrigações sob estes Termos sem consentimento prévio por escrito da Cointrade Crypto Exchange, inclusive por força de lei ou em conexão com qualquer mudança de controle. A Cointrade Crypto Exchange pode ceder ou transferir qualquer ou todos os seus direitos sob estes Termos, no todo ou em parte, sem obter seu consentimento ou aprovação.\u003Cbr\u003E REGISTO DE UMA CONTA NA COINTRADE CRYPTO EXCHANGE\u003Cbr\u003E 31. É necessário criar uma conta na Cointrade Crypto Exchange para usar nossa Plataforma na ordem correta e com toda a sua funcionalidade, bastando para tanto, informar um e-mail válido e senha.\u003Cbr\u003E 32. O procedimento de KYC pode ser exigido a qualquer momento, se passar a ser obrigatório pelas autoridades competentes.\u003Cbr\u003E 33. Quando você cria uma conta Cointrade Crypto Exchange, você se compromete a\u003Cbr\u003E 33.1. criar uma senha forte que você não use para outros sites, serviços on-line ou offline;\u003Cbr\u003E 33.2. manter a segurança de sua conta Cointrade Crypto Exchange protegendo sua senha e restringindo o acesso à sua conta Cointrade Crypto Exchange;\u003Cbr\u003E 33.3. notificar-nos imediatamente se descobrir ou suspeitar de qualquer violação de segurança relacionada à sua conta Cointrade Crypto Exchange;\u003Cbr\u003E 33.4. assumir a responsabilidade por todas as atividades que ocorram sob sua Conta Cointrade Crypto Exchange e aceitar todos os riscos de qualquer acesso autorizado ou não autorizado à sua Conta Cointrade Crypto Exchange, na máxima extensão permitida por lei.\u003Cbr\u003E DEPÓSITO E RETIRADA DE ATIVOS NA CONTA COINTRADE CRYPTO EXCHANGE\u003Cbr\u003E 34. Nossa Plataforma permite que os Usuários façam depósito em moeda FIAT ou ativos criptográficos para a Conta da Cointrade Crypto Exchange, ou ainda por emissão de boleto, através do serviço de terceiros, os quais o usuário declara estar ciente que se tratam apenas de prestadores de serviço.\u003Cbr\u003E 34.1. A Cointrade Crypto Exchange não se responsabiliza por problemas ocorridos na emissão de boletos através do parceiro;\u003Cbr\u003E 34.2. Os boletos serão emitidos com o prazo D+1.\u003Cbr\u003E 35. Qualquer taxa cobrada por parceiros, será repassada diretamente para o usuário.\u003Cbr\u003E 36. Ao solicitar o depósito de qualquer quantia para a plataforma, poderá ser gerado um novo valor acrescido de centavos, o que irá identificar seu depósito naquele momento. Caso seja gerado, o uso dos centavos será obrigatório. Qualquer erro relativo ao novo valor gerado acrescido de centavos impossibilitará a identificação do seu depósito. Caso ocorra, o usuário deverá comprovar que foi o depositante, através de carta do banco responsável pelo depósito, para possibilitar a tentativa de recuperação.\u003Cbr\u003E 37. Você garante e isenta a Cointrade Crypto Exchange de quaisquer reivindicações, exigências e danos, sejam diretos, indiretos, consequentes ou especiais, ou quaisquer outros danos de qualquer tipo, incluindo, perda de uso, perda de lucros ou perda de dados, originados ou de qualquer forma relacionados com o seu depósito ou transferência de retirada solicitada.\u003Cbr\u003E 38. Você entende e reconhece que um endereço para receber um ativo criptografado será criado automaticamente assim que você solicitar a transferência do Depósito, e antes que qualquer ativo criptografado possa ser enviado para a sua Conta Cointrade Crypto Exchange, você deve autorizar de forma completa e irrevogável a sua criação. 39. Quando você solicita que seja depositado ou retirado ativos de criptografia da sua conta, você autoriza a Cointrade Crypto Exchange a executar essa transferência através da Plataforma.\u003Cbr\u003E 40. Você é o único responsável pelo uso do serviço de terceiros e concorda em cumprir todos os termos e condições aplicáveis a eles. 40.1. Cada moeda possui sua particularidade, a qual o usuário é o único responsável em cumprir, isentando a Cointrade Crypto Exchange de qualquer responsabilidade pelo não cumprimento de tais particularidades.\u003Cbr\u003E 41. Em alguns casos, o serviço terceirizado pode rejeitar seus ativos de criptografia a serem processados, suspender a Transferência de Depósito ou Saque de seus ativos de criptografia ou não suportar a Transferência, ou pode estar indisponível. Você concorda que não responsabilizará a Cointrade Crypto Exchange por quaisquer reivindicações, demandas e danos, sejam diretos, indiretos, consequentes ou especiais, ou quaisquer outros danos de qualquer tipo, incluindo, perda de uso, perda de lucros ou perdas de dados, originada ou de qualquer maneira conectada com tais rejeições ou suspensões de depósito ou saque.\u003Cbr\u003E 42. Sujeito aos termos e condições destes Termos, envidaremos esforços comercialmente razoáveis para registrar todas as Transferências em uma base imediata assim que possível. No entanto, o momento associado ao Depósito ou Retirada de ativos de criptografia depende, entre outras coisas, do desempenho de serviços de terceiros e não garantimos que os ativos de criptografia serão Depositados ou Retirados em qualquer período de tempo específico. Você entende e reconhece que todos os atrasos são possíveis; você garante e isenta a Cointrade Crypto Exchange de quaisquer reivindicações, exigências e danos, sejam diretos, indiretos, consequentes ou especiais, ou quaisquer outros danos de qualquer tipo, incluindo, perda de uso, perda de lucros ou perda de dados, decorrente ou de qualquer forma relacionado com o atraso de transferência, seja originado de nossa falha ou não.\u003Cbr\u003E COMÉRCIO DE ATIVOS CRYPTO\u003Cbr\u003E 43. O comércio de ativos Crypto ocorre entre os usuários.\u003Cbr\u003E 44. Quando você envia uma ordem de negociação através da Plataforma, você autoriza a Cointrade Crypto Exchange a\u003Cbr\u003E 44.1. registrar uma transferência de seus ativos criptográficos de/para/em sua conta Cointrade Crypto Exchange.\u003Cbr\u003E 44.2. quando aplicável, reserve seus ativos de criptografia na sua conta Cointrade Crypto Exchange de acordo com tal ordem de comércio.\u003Cbr\u003E 44.3. e cobrar quaisquer taxas aplicáveis por tal registro.\u003Cbr\u003E 45. Você reconhece e concorda que, em relação à sua atividade de negociação, nossa Plataforma\u003Cbr\u003E 45.1 não está atuando como seu corretor, intermediário, agente ou consultor ou em qualquer capacidade fiduciária;\u003Cbr\u003E 45.2. não está agindo como parte da transferência de um determinado ativo criptografado.\u003Cbr\u003E 46. Cada ordem de transação colocada cria diferentes taxas de câmbio de mercado. Você reconhece e concorda que as informações de tarifas disponibilizadas por meio da Plataforma podem diferir das tarifas vigentes disponibilizadas por outras fontes fora da Plataforma.\u003Cbr\u003E 47. Particularmente durante períodos de alto volume, falta de liquidez, movimento rápido ou volatilidade no mercado para qualquer ativo criptografado, a taxa real de mercado na qual uma transação de mercado é executada pode ser diferente da taxa predominante indicada via Plataforma no momento da execução da sua Transação comercial. Você entende que não somos responsáveis por tais flutuações de taxas.\u003Cbr\u003E 48. As tarifas disponibilizadas através da Plataforma não devem ser consideradas como um investimento ou aconselhamento financeiro, ou referidas como tal, e não podem ser usadas como base de estratégia de investimento.\u003Cbr\u003E TAXAS DA COINTRADE CRYPTO EXCHANGE\u003Cbr\u003E 49. Os primeiros 20.000 (vinte mil) inscritos na Plataforma terão isenção do pagamento de taxas até o mês de dezembro de 2018, após oque encerrará a promoção e taxas passarão a ser cobradas para as transações concluídas por meio da Plataforma.\u003Cbr\u003E 50. Você concorda em pagar as taxas para Transferências concluídas por meio da Plataforma, conforme será definido pelas Taxas e Limites, que podem ser alteradas periodicamente. As alterações nas Taxas são efetivas a partir da data indicada no lançamento das Taxas e Limites revisados, e serão aplicadas prospectivamente a quaisquer Transferências que ocorram após a data de tais Taxas revisadas.\u003Cbr\u003E 51. Pagamento de taxas. Você nos autoriza, ou a nosso processador de pagamentos designado, a cobrar ou deduzir os ativos criptográficos da sua conta Cointrade Crypto Exchange por quaisquer taxas devidas relacionadas às negociações concluídas por meio da Plataforma.\u003Cbr\u003E DIREITOS AUTORAIS E OUTROS DIREITOS DE PROPRIEDADE INTELECTUAL.\u003Cbr\u003E 52. Cointrade Crypto Exchange e o logotipo , nomes comerciais, marcas nominativas e marcas de design são marcas comerciais da empresa Dinamiam S/A. Você concorda em não se apropriar, copiar, exibir ou usar as Marcas Cointrade Crypto Exchange ou outro conteúdo sem permissão prévia expressa por escrito para fazê-lo.\u003Cbr\u003E CONTEÚDO DE TERCEIROS\u003Cbr\u003E 53. Ao usar nossa Plataforma, você pode visualizar o conteúdo de terceiros. Nós não controlamos, endossamos ou adotamos (a menos que expressamente declarado por nós) qualquer Conteúdo de Terceiros e não teremos responsabilidade pelo Conteúdo de Terceiros, incluindo, sem limitação, materiais que possam ser enganosos, incompletos, errôneos, ofensivos, indecentes ou de outra forma censurável. Além disso, seus negócios ou correspondências com tais terceiros são exclusivamente entre você e terceiros. Não somos responsáveis por qualquer perda ou dano de qualquer tipo incorrido como resultado de tais negociações, e você entende que seu uso do Conteúdo de Terceiros e suas interações com terceiros são de sua responsabilidade.\u003Cbr\u003E 54. A Cointrade Crypto Exchange é contra qualquer atividade ilegal, tráfico de drogas, de seres humanos, de órgãos e qualquer outro tráfico ilegal, caça furtiva, pornografia, comércio de armas, terrorismo e financiamento criminal, corrupção, suborno e lavagem de dinheiro.\u003Cbr\u003E"},"markets":{"market_list":{"all":"Todos","brl":"BRL Mercado","btc":"BTC Mercado","bhc":"BHC Mercado","btg":"BTG Mercado","dash":"DASH Mercado","eth":"ETH Mercado","zec":"ZEC Mercado","dgb":"DGB Mercado","xrp":"XRP Mercado","smart":"Smart Mercado","iota":"IOTA Mercado","ltc":"LTC Mercado","zcr":"ZCR Mercado","tusd":"TUSD Mercado","xem":"XEM Mercado","rbtc":"RBTC Mercado","rif":"RIF Mercado","xar":"XAR Mercado"}},"markets_overview":{"market_depth":"Profundidade do Mercado"}}};
I18n.locale = 'pt-BR';


