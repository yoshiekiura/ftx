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

I18n.translations = {"en":{"brand":"Cointrade","submit":"Submit","cancel":"Cancel","confirm":"Confirm","banks":{"_065":"Andbank","_654":"Banco A.j. Renner S.A.","_246":"Banco Abc/brasil S.A.","_121":"Banco Agibank S.A.","_025":"Banco Alfa S.A.","_213":"Banco Arbi S.A.","_096":"Banco B3 S.A.","_036":"Banco Bem S.a..","_122":"Banco Berj S.A.","_318":"Banco Bmg Comercial S.A.","_752":"Banco Bnp Paribas Brasil S.A.","_107":"Banco Bocom Bbm S.A.","_069":"Banco Bpn Brasil S.A.","_063":"Banco Bradescard S.A.","_237":"Banco Bradesco S.A.","_218":"Banco Bs2 S.A.","_473":"Banco Caixa Geral Brasil S.A.","_412":"Banco Capital S.A.","_040":"Banco Cargill S.A.","_266":"Banco Cedula S.A.","_745":"Banco Citibank S.A.","_756":"Banco Cooperativo do Brasil S.A.","_748":"Banco Cooperativo Sicredi S.A.","_505":"Banco Credit Suisse (brasil) S.A.","_003":"Banco da Amazonia S.A.","_083":"Banco da China Brasil S.A.","_707":"Banco Daycoval S.A.","_070":"Banco de Brasilia S.A.","_300":"Banco de La Nacion Argentina S.A.","_487":"Banco Deutsche Bank S.A.","_001":"Banco do Brasil S.A.","_047":"Banco do Estado de Sergipe S.A.","_021":"Banco do Estado do Espirito Santo S.A.","_037":"Banco do Estado do Para S.A.","_041":"Banco do Estado do Rio Grande do Sul S.A.","_004":"Banco do Nordeste do Brasil S.A.","_265":"Banco Fator S.A.","_224":"Banco Fibra S.A.","_626":"Banco Ficsa S.A.","_394":"Banco Finasa Bmc S.A.","_612":"Banco Guanabara S.A.","_604":"Banco Industrial do Brasil S.A.","_653":"Banco Indusval S.A.","_077":"Banco Intermedium","_074":"Banco J. Safra S.A.","_376":"Banco Jp Morgan S.A.","_600":"Banco Luso Brasileiro S.A.","_389":"Banco Mercantil do Brasil S.A.","_755":"Banco Merrill Lynch S.A.","_746":"Banco Modal S.A.","_456":"Banco Mufg Brasil S.A.","_079":"Banco Original do Agronegocio S.A.","_212":"Banco Original S.A.","_208":"Banco Pactual S.A.","_623":"Banco Pan","_254":"Banco Parana Banco S.A.","_611":"Banco Paulista S.A.","_643":"Banco Pine S.A.","_747":"Banco Rabobank International Br S.A.","_633":"Banco Rendimento S.A.","_741":"Banco Ribeirao Preto S.A.","_422":"Banco Safra S.A.","_033":"Banco Santander S.A.","_743":"Banco Semear S.A.","_366":"Banco Societe Generale Brasil S.A.","_637":"Banco Sofisa","_243":"Banco Stock Maxima S.A.","_464":"Banco Sumitomo Mitsui Brasileiro S.A.","_634":"Banco Triangulo S.A.","_018":"Banco Tricury S.A.","_655":"Banco Votorantim S.A.","_610":"Banco Vr S.A.","_222":"Bco Credit Agricole Brasil S.A.","_017":"Bny Mellon Banco S.A.","_125":"Brasil Plural S.A.","_097":"Cc Centralcredi","_136":"Cc Unicred do Brasil","_320":"Ccb Brasil","_098":"Cerdialinca Cooperativa Credito Rural","_739":"Cetelem","_163":"Commerzbank","_085":"Cooperativa Central de Credito / Ailos","_099":"Cooperativa Central Econ. Cred. Mutuo Un","_089":"Cooperativa de Credito Rural da Regiao D","_010":"Credicoamo Credito Rural Cooperativa","_104":"Cx Economica Federal","_094":"Finaxis","_132":"Icbc do Brasil Banco Multiplo S.A.","_630":"Intercap","_341":"Itaú Unibanco S.A.","_076":"Kdb do Brasil","_757":"Keb Hana do Brasil","_753":"Nbc Bank Brasil Sa/banco Multiplo","_260":"Nu Pagamentos S.A.","_613":"Omni Banco S A","_120":"Rodobens","_751":"Scotiabank Brasil S.a. Banco Multiplo","_082":"Topazio","_084":"Uniprime Norte do Parana Cc","_119":"Western Union","_124":"Woori Bank"},"fund_sources":{"manage_bank_account":"Bank Account Management","manage_bank_account_desc":"To facilitate the choice of bank withdrawals address","manage_bank_account_alert_deposit":"Please register here the bank accounts that will be used for deposits in Reais, just as it is indispensable to inform your CPF.","manage_bank_account_alert_withdraw":"Please register here the bank accounts that will be used for withdrawals in Reais, just as it is indispensable to inform your CPF.","manage_bank_account_info":"* Caution If your bank's digit is X, please substitute 0.","manage_bank_account_required":"All fields are mandatory.","msg_time_close":"Brazilian time for deposit: 09:00-16:30, except Itaú account (TEF)","copied":"Copied!","manage_coin_address":"Coin Address Management","manage_coin_address_desc":"To facilitate the choice of coin withdrawals address","select_region":"Select Region","brasil":"Brazil","type_deposit":"Type of deposit","type_transfer":"Type of transfer","select_type":"Select the type","another":"Others","fiat":"REAIS","region":"Region","bank_transfer":"Bank transfer","bank_slip":"Bank slip","bank":"Bank","account":"Account","cpf":"CPF/CNPJ","agency":"Agency","label_agency":"Agency","label_account-dig":"Account-dig","digit":"dig","label":"Label","address":"Address","action":"Action","add":"Add","remove":"Remove","default":"Default","select_account":"Select Account"},"payment_slip":{"tax":"Tax","click_slip":"Click to print the bank slip","bank":"Bank","label_name":"Name","label_cpf":"CPF","label_cnpj":"CNPJ","label_cpfcnpj":"CPF or CNPJ","label_phone":"Num.Mobile","label_email":"E-mail","label_address":"Address","label_city":"City","label_uf":"UF","label_state":"State","label_cep":"Zip Code","label_complement":"Complement","label_number":"Number","title":"Bank Slip generation","label":"Apelido","address":"Address","action":"Action","add":"Add","remove":"Remove","default":"Default","desc":"The information reported here will be used in the generation of the bank slip.","btn_generete_slip":"Generate bank slip","label_amount":"R$ 00000","value_req":"Fill all inputs","label_tabDeposit":"Deposits","label_tabBank":"Bank Slip","amount":"Amount","amount_total":"Total Amount"},"funds":{"deposit":"Deposit","withdraw":"Withdraw","tooltip_status":{"accepted":{"text":"The informed Txid was processed successfully. Please check your balance.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"checked":{"text":"Order reviewed by Admin.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"submitting":{"text":"Txid is being processed.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitted":{"text":"The deposit order has been submitted.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"cancelled":{"text":"Canceled order.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"rejected":{"text":"Order rejected. Please contact our support.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"warning":{"text":"The informed Txid has not been processed in the last 2 hours. Please contact our support.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"},"suspect":{"text":"Irregular order. Please contact our support.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"}},"deposit_modal":{"tef":"TEF (Transfer between Itaú accounts)","ted":"TED (Electronic Transfer Available)","dia":"DIA (Cash deposit Identified at the agency)","session_expire":"Time expired, deposit order automatically canceled.","deposit_code":"Code for deposit identification","content_header":" \u003Ctable width=\"100%\" style=\"background:#28363D;\"\u003E \u003Ctbody\u003E \u003Ctr align=\"center\"\u003E \u003Ctd style=\"padding:10px 10px 10px 10px; display:flex; justify-content: center; align-items:center;\"\u003E \u003Cimg  src=\"logo_cx_email.png\" \u003E \u003C/td\u003E \u003C/tr\u003E \u003C/tbody\u003E \u003C/table\u003E \u003Cdiv style=\"padding-left:35px;padding-right:35px;padding-top:10px;\"\u003E \u003Cspan style=\"font-size:30px;\"\u003EATTENTION! Information on how to make a deposit.\u003C/span\u003E\u003Cbr\u003E \u003Cspan style=\"font-size:20px;\"\u003EYour order %{type_transfer_description} was created in the system.\u003C/span\u003E \u003C/div\u003E","content_tef":"    \u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; color:white; background-color:#EA5E6E;\"\u003E \u003Cspan style=\"font-size:20px;\"\u003EAMOUNT: \u003Cspan style=\"font-size:30px;\"\u003ER$ %{valor_deposito}\u003C/span\u003E\u003C/span\u003E\u003Cbr\u003E \u003C/span\u003E \u003C/div\u003E \u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; font-weight:bold; color:grey\"\u003E Bank details for transfer:\u003Cbr\u003E Bank: 341 - Itaú\u003Cbr\u003E Agency: 7307\u003Cbr\u003E Account: 08782-0\u003Cbr\u003E COINBR SERVICOS DIGITAIS LTDA\u003Cbr\u003E CNPJ: 11.768.654/0001-86\u003Cbr\u003E Data: %{date_create}\u003C/br\u003E Time: %{time_created}\u003C/br\u003E \u003Cdiv\u003E \u003Cbr\u003E \u003Cbr\u003E","content_ted":"  \u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; color:white; background-color:#EA5E6E;\"\u003E \u003Cspan style=\"font-size:20px;\"\u003EAmount: \u003Cspan style=\"font-size:30px;\"\u003ER$ %{valor_deposito}\u003C/span\u003E\u003C/span\u003E\u003Cbr\u003E \u003Cspan\u003E\u003Cspan style=\"font-weight:bold\"\u003E*ATTENTION\u003C/span\u003E: Make the deposit according to the exact amount above.\u003Cbr\u003E \u003Cspan style=\"font-size:20px;\"\u003EDue date: %{expire}\u003Cspan\u003E \u003C/span\u003E \u003C/div\u003E\n\u003Cdiv style=\"width:100%; padding-top:15px;padding-bottom:15px;padding-left:35px;padding-right:35px; font-weight:bold; color:grey\"\u003E Bank details for transfer:\u003C/br\u003E CPF: %{samurai_code}\u003C/br\u003E Bank: 341 - Itaú\u003C/br\u003E Agency: 7307\u003C/br\u003E Account: 08782-0\u003C/br\u003E COINBR SERVICOS DIGITAIS LTDA\u003C/br\u003E CNPJ: 11.768.654/0001-86\u003C/br\u003E \u003C/br\u003E Date: %{date_create}\u003C/br\u003E Time: %{time_created}\u003C/br\u003E \u003C/div\u003E","content_footer_tef":"\u003Cdiv\u003E* The values for minimum transfer of R $ 25.00 (twenty five reais).\nTransfers effected that are less than R $ 25.00 (twenty five reais) will not be compensated, and will be returned upon payment of a fee of R $ 20.00 (twenty reais).\u003Cbr\u003E\nOs valores de depósitos BRL (em Reais) realizados em toda nossa plataforma terminam com 08 centavos para possibilitar o processo de verificação automática,garanta que o valor depositado inclua os 08 centavos requisitados para o mesmo ser corretamente identificado.\u003Cbr\u003E\nConfirmation of the deposit may take up to 3 business days, however, the current average time is up to 3 hours.","content_footer_ted":"\u003Cdiv style=\"width:100%;padding-bottom:15px;padding-left:35px;padding-right:35px; font-weight:bold; color:grey; font-size:13px\"\u003E\u003Cspan style=\"color:#EA5E6E;\"\u003E* BRL deposit amounts (in Reais) made across our platform end with 08 cents to enable the automatic verification process, guarantee that the amount deposited includes the 08 cents required for it to be correctly identified.\u003C/span\u003E\u003Cbr\u003E Confirmation of the deposit may take up to 3 business days, however, the current average time is up to 6 hours. \u003Cbr\u003E From the transfer of international banks that have not been successfully completed, please forward emails to financeiro@cointrade.cx\u003C/span\u003E\u003C/div\u003E"},"currency_name":{"btc":"BTC","brl":"BRL","doge":"DOGE","pts":"PTS","ltc":"LTC","bch":"BCH","btg":"BTG","dash":"DASH","eth":"ETH","zec":"ZEC","dgb":"DGB","xrp":"XRP","smart":"Smart","iota":"IOTA","zcr":"ZCR","tusd":"TUSD","xem":"XEM","rbtc":"RBTC","rif":"RIF","xar":"XAR"},"deposit_brl":{"title":"At our platform","title2":"At your bank","message_validation2":"Could not connect to BankSlip provider!","message_validation":"Please fill in all fields","message_creation":"Created successfully","slip_buttom":"BankSlip","title_transfer":"Brazilian Real transfer bank","desc":"Follow the steps below:","desc_item_1":"Enter the value of the deposit;","desc_item_2":"Access the MANAGE ACCOUNTS option and register your bank account;","desc_item_3":"Click the Submit button;","desc_item_4":"Information about the procedure will be displayed on the screen and sent by email.","desc_item_5":"Transfer the money to the account of COINBR SERVICOS DIGITAIS LTDA;","desc_item_6":"Minimum amount of R$ 25.08 with identification of the CPF;","desc_item_7":"ALWAYS send your proof of deposit to \u003Ccomprovante@cointrade.cx\u003E. Your deposit will be confirmed as soon as your money is received.","desc_item_8":"Time for deposit: 09:00 to 16:30 Brazilian time. Any ted that is generated on the day and does not run on it until 4.30pm will be rejected, generating a charge of R $ 20.00 for the chargeback.","attention":"Attention: We DO NOT accept transfers from different account holders, subject to 10% refund fee. The name of your bank account must match with name of your Cointrade Registration, otherwise your deposit will not be identified.","attention2":"Deposit amounts (in Reais) made on our entire platform end with 08 cents to enable the automatic verification process.","title_slip":"Deposit Bank Slip","observations_slip":"Observations","desc_on_slip":{"desc_item_1":"Minimum amount of R$ 25.08 with identification of the CPF;","desc_item_2":"The ticket processing company charges a fee of 0.0% plus R$ 6.50;","desc_item_3":"This fee is added to the total amount of the ticket generated, where the processor will discount its fees when it is cleared."},"from":"From","to":"To","bank_information":{"title":"Our bank information","label_bank":"Bank","bank":"341 - Itaú","label_recipient":"Beneficiary","recipient":"COINBR SERVICOS DIGITAIS LTDA","label_cnpj":"CNPJ","cnpj":"11.768.654/0001-86","label_agency":"Agency","agency":7307,"label_account":"Account","account":"08782-0","place_holder_amount":"Minimum value 25 Reais"},"deposit_name":"Your Name","deposit_account":"Deposit Account","add":"Add","manage":"MANAGE ACCOUNTS","amount":"AMOUNT","type":"Type","document":"CPF","document_mask":"000.000.000-00","min_amount":"At least 25,00 Brazilian Reais","to_account":"TED/DOC","account_detail":"Itaú Ag: 7307 Conta: 08782-0","to_name":"Name","to_bank_name":"Bank Name","opening_bank_name":"Brazilian Registration CNPJ","remark":"Referral Code (Transfer identification code)","label_tabDeposit":"Deposits","label_tabBank":"Bank Slip","label_deposit_ammount":"Amount","label_deposit_value":"Select the type of transaction?","label_deposit_vlr":"Deposit Amount.","label_desc":"What type will the transaction be made from?","deposit_information_title":"ATTENTION! INFORMATION ON HOW TO MAKE THE DEPOSIT","message_error":"An error occurred, please try again later","message_error_limit":"The minimum deposit amount is R$25 reais."},"deposit_btc":{"title":"BTC Deposit"},"deposit_bch":{"title":"BCH Deposit"},"deposit_btg":{"title":"BTG Deposit"},"deposit_dash":{"title":"DASH Deposit"},"deposit_eth":{"title":"ETH Deposit"},"deposit_zec":{"title":"ZEC Deposit"},"deposit_dgb":{"title":"DGB Deposit"},"deposit_xrp":{"title":"XRP Deposit"},"deposit_smart":{"title":"Smart Deposit"},"deposit_iota":{"title":"IOTA Deposit"},"deposit_ltc":{"title":"LTC Deposit"},"deposit_zcr":{"title":"ZCR Deposit"},"deposit_tusd":{"title":"TUSD Deposit"},"deposit_xem":{"title":"XEM Deposit"},"deposit_rbtc":{"title":"RBTC Deposit"},"deposit_rif":{"title":"RIF Deposit"},"deposit_xar":{"title":"XAR Deposit"},"deposit_coin":{"address":"Address","new_address":"New Address","confirm_gen_new_address":"You sure want to generate a new deposit address?","open-wallet":"Please use your common wallet services, local wallet, mobile terminal or online wallet, select a payment and send.","detail":"Please paste the address below in your wallet, and fill in the amount you want to deposit, then confirm and send.","scan-qr":"Scanning QR code to Pay for In the mobile terminal wallet.","after_deposit":"Once you complete sending, you can check the status of your new deposit below.","generate-new":"Generate new address","copy":"Copy","txidText":"After generating your deposit, you must enter here the Txid (transaction ID)","txidText2":"generated by the platform of your choice. To check your deposits,","click":"click here!","insertTxid":"Insert your Txid","msg1":"Your TXID has been successfully saved and we will investigate it to credit your deposit as soon as possible.","msg2":"You already have a deposit order with this Txid number.","tag_xrp_tip":"*In order to make an XRP deposit it is necessary to use the TAG,","tag_xrp_tip_2":"otherwise your deposit will be forfeited."},"deposit_history":{"coin":"Coin","fiat":"REAIS","title":"HISTORY","describe":"All cryptos deposits addresses have been updated.","describe1":"Before making a new crypto deposit on the platform,","describe2":"make sure you are using the correct address.","describe3":"All crypto addresses have been updated. \u003Cbr/\u003E Before you make a new crypto order on the platform,\u003Cbr/\u003E make sure you are using the correct address","number":"#","identification":"Identification Code","time":"Time","txid":"Transaction ID","confirmations":"Confirmations","from":"From","imformation_from":"Transaction Information","slip_type":"BankSlip","amount":"Amount","state_and_action":"State/Action","inserted_txid":"Inserted Txid","cancel":"cancel","no_data":"There is no history data","submitting":"Submitting","cancelled":"Cancelled","submitted":"Submitted","accepted":"Accepted","rejected":"Rejected","checked":"Checked","warning":"Warning","suspect":"Suspect","transaction_type":"Transaction type","validator":"Validator"},"withdraw_brl":{"title":"Brazilian Real Withdraw","desc":"Follow the steps below:","intro":"Select the bank to cash withdrawal amount and enter the account number and complete submission.","intro_2":"Your bank account and name must be consistent with the real-name authentication name.","intro_3":"If your account registered for redemption is from Banco Itaú, no transaction fee will be charged. If you wish to make a redemption for a non-Itaú bank account, the TED fee will be charged in the amount of R $ 10.90.","intro_4":"For crypto coins withdrawals higher than the value 5 (five), the release is the result of conference management team cointrade.cx.","intro_5":"The value in reais will be charged a fee of 0.25% on the amount drawn.","intro_6":"If you wish to make a redemption for a non-Itaú account, the TED fee will be charged in the amount of R $ 10.90.","intro_7":"Opening hours: 09:00 to 16:30 Brazilian time. Any ted that is generated on the day and does not run on it until 4.30pm will be rejected, generating a charge of R $ 20.00 for the chargeback.","attention":"Working Hours: 9:00 - 18:00","account_name":"Account Name","withdraw_address":"Withdraw Address","balance":"Available Amount","balance_tip":"Amount available for withdrawal","locked":"Amount in trading","locked_tip":"Value blocked due to open trade orders","total":"Amount","total_tip":"Sum of available value with locked traded amounts","withdraw_amount":"Withdraw Amount","manage_withdraw":"Manage Withdraw","fee_explain":"About Fee","min":"At least","withdraw_all":"Withdraw all","message_success":"Withdrawn"},"withdraw_btc":{"title":"BTC Withdraw"},"withdraw_bch":{"title":"BCH Withdraw"},"withdraw_btg":{"title":"BTG Withdraw"},"withdraw_dash":{"title":"DASH Withdraw"},"withdraw_eth":{"title":"ETH Withdraw"},"withdraw_zec":{"title":"ZEC Withdraw"},"withdraw_dgb":{"title":"DGB Withdraw"},"withdraw_xrp":{"title":"XRP Withdraw"},"withdraw_smart":{"title":"Smart Withdraw"},"withdraw_iota":{"title":"IOTA Withdraw"},"withdraw_ltc":{"title":"LTC Withdraw"},"withdraw_zcr":{"title":"ZCR Withdraw"},"withdraw_tusd":{"title":"TUSD Withdraw"},"withdraw_xem":{"title":"XEM Withdraw"},"withdraw_rbtc":{"title":"RBTC Withdraw"},"withdraw_rif":{"title":"RIF Withdraw"},"withdraw_xar":{"title":"XAR Withdraw"},"withdraw_coin":{"intro":"Please fill in the address and amount, then submit the form.","label":"Denomination","balance":"Balance","amount":"Amount","manage_withdraw":"Manage Address","min":"At least","withdraw_all":"Withdraw all","fee_explain":"About Fee","with":"Amount of service fee."},"withdraw_history":{"title":"Withdraw History","number":"Number","withdraw_time":"Time","withdraw_account":"Withdraw Account","withdraw_address":"Address","withdraw_amount":"Amount","actual_amount":"Actual Amount","fee":"Fee","fee_ted":"TED Fee","fee_withdraw":"Withdraw Fee","miner_fee":"Fee","state_and_action":"State/Action","cancel":"Cancel","no_data":"There is no history data","coin":"Coin","inserted_txid":"Txid provided by Stratum","submitting":"Submitting","submitted":"Submitted","rejected":"Rejected","accepted":"Accepted","suspect":"Suspect","processing":"Processing","coin_ready":"Coin Ready","coin_done":"Coin Done","done":"Done","almost_done":"Almost Done","canceled":"Canceled","failed":"Failed","cancelled":"Cancelled","checked":"Checked","warning":"Warning","validator":"Validator","value":10.9,"value_percent":"0.25%","fee_info":"BRL withdraw: Fee of 0.25% on the total amount of withdrawal + Fee of TED R$10,90 Crypto withdraw: Network amount Fee of each crypto.","tooltip_status":{"accepted":{"text":"The withdrawal was processed successfully. Please check in your personal wallet.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"done":{"text":"The withdrawal was processed successfully. Please check in your personal wallet.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"checked":{"text":"Order reviewed by Admin.","icon":"\u003Ci class=\"far fa-check-circle\"\u003E\u003C/i\u003E"},"almost_done":{"text":"The withdrawal order is being submitted.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitting":{"text":"The withdrawal order is being submitted.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"submitted":{"text":"The withdrawal order has been submitted.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"},"cancelled":{"text":"Order rejected.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"rejected":{"text":"Order rejected.","icon":"\u003Ci class=\"far fa-times-circle\"\u003E\u003C/i\u003E"},"warning":{"text":"No transactions have been processed to date. Please contact our support.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"},"suspect":{"text":"Irregular order. Please contact our support.","icon":"\u003Ci class=\"fas fa-exclamation-triangle\"\u003E\u003C/i\u003E"},"processing":{"text":"The service order is being processed.","icon":"\u003Ci class=\"far fa-clock\"\u003E\u003C/i\u003E"}}}},"auth":{"please_active_two_factor":"Please set mobile number or google authenticator first.","submit":"Submit","otp_placeholder":"6-digit password","google_app":"Google Authenticator","sms":"SMS Verification Messages","send_code":"Send Code","send_code_alt":"Resend in COUNT seconds","hints":{"app":"Google Authenticator will re-generate a new password every thirty seconds, please input timely.","sms":"We'll send a text message to you phone with verify code."},"term_agree":"SERVICE TERMS\u003Cbr\u003E 1. The present Term of Services establishes the conditions of use of the Platform between Cointrade Crypto Exchange and its Users.\u003Cbr\u003E 2. Cointrade Crypto Exchange does not buy and sell coins. The objective of the Platform is to bring users closer to buying and selling their own crypto-coins, offering features to facilitate transactions.\u003Cbr\u003E 3. To transact on the Cointrade Crypto Exchange Platform you must register, simply by providing a valid email and password, at which time you declare and acknowledge that you have read, understood and irrevocably accepted this Agreement of its attachments and / or appendices, as well as documentation and information published on the site.\u003Cbr\u003E 4. This Term of Service, its attachments, appendices, services, tools and conditions may be modified, amended, modified, deleted or updated by Cointrade Crypto Exchange at any time without notice. Reason why, you should check frequently to confirm that your copy and the understanding of this Term of Use, attachments and appendices are up to date and correct. The non-termination or use of any services after the effective date of any incorporations, changes, modifications or updates constitutes implicitly and unequivocally your acceptance of the modifications by such amendments, changes or updates. If you do not agree to any of the terms here, please do not sign up for and continue to use the cointrade.cx site.\u003Cbr\u003E 5. Use of the site and any services is void where prohibited by applicable law.\u003Cbr\u003E 6. In this act you represent and warrant that\u003Cbr\u003E 6.1.You are at least 18 years old, full civil capacity, according to your relevant jurisdiction;\u003Cbr\u003E 6.2.Have not previously been suspended or removed from our services;\u003Cbr\u003E 6.3.Have full power and authority to enter into this legal relationship and, in so doing, shall not violate any other legal relationship;\u003Cbr\u003E 6.4.Use our Platform with your own email;\u003Cbr\u003E 6.5.The encryption assets that you transfer to the platform are not sold, encumbered, disputed or under arrest, and that there is no third party right over them;\u003Cbr\u003E 6.6.You will immediately terminate your use of our services if you are a resident or become a state or regional resident, where encryption asset transactions are prohibited or require special approval, permission or authorization of any kind, which Cointrade Crypto Exchange does not has obtained;\u003Cbr\u003E 6.7.You agree that you will not violate any law, contract, intellectual property or other right of any third party or you will commit an unlawful act and that you are solely responsible for your conduct in using our Platform.\u003Cbr\u003E 7. Without prejudice to the generality of the foregoing, you represent, agree, accept and warrant that you will not.\u003Cbr\u003E 7.1.Use the Platform in any manner that may interfere with, disrupt, adversely affect, or inhibit other users from using our Platform with complete functionality, or that may damage, disable, overburden, or impair the Platform's operation in any manner;\u003Cbr\u003E 7.2.Use the Platform to pay, support or otherwise engage in any illegal gambling activities; fraud; money laundry; or terrorist activities; or any other illegal activities;\u003Cbr\u003E 7.3.Use any robot, spider, crawler, scraper or other automated means or interface not provided by Cointrade Crypto Exchange to extract data;\u003Cbr\u003E 7.4.Use or attempt to use another user account without authorization;\u003Cbr\u003E 7.5.Attempt to circumvent any content filtering techniques that Cointrade Crypto Exchange uses, or attempt to access any service or area of ​​the Platform that you are not authorized to access;\u003Cbr\u003E 7.6. Develop any third party applications that interact with the Platform without the prior written consent of Cointrade Crypto Exchange.\u003Cbr\u003E OF RISK\u003Cbr\u003E 8. You acknowledge and agree that you will use the Platform at your own risk. The risk of loss in dealing in cryptographic assets can be substantial, so you should consider whether this negotiation is appropriate for you. There is no guarantee against loss on the Site.\u003Cbr\u003E 8.1 You acknowledge and agree to the possibility of the following;\u003Cbr\u003E 8.1.a You can support a total loss of active crypto in your Cointrade Crypto Exchange account.\u003Cbr\u003E 8.1.b Under certain market conditions, you may find it difficult to settle a position, such as when liquidity in the market is insufficient because it has reached a daily price fluctuation threshold (\"threshold movement\").\u003Cbr\u003E 8.1.c The use of orders such as \"stop-loss\" or \"stop-limit\", will not necessarily limit their losses to the desired values, since market conditions may make it impossible to execute such orders.\u003Cbr\u003E 8.1.d The points mentioned above apply to all encrypted assets. This brief statement can not, however, expose all risks and other aspects associated with the trading of cryptographic assets and should not be considered as any advice.\u003Cbr\u003E 8.2. You acknowledge that there are risks associated with the use of a  Internet-based commerce, including, but not limited to, hardware failures, software and Internet connections. You acknowledge that the Cointrade Crypto Exchange shall not be liable for any communication failures, interruptions, errors, distortions or delays that you may have in using the Platform, regardless of the cause.\u003Cbr\u003E 8.3. The Platform and its related Services are based on the Blockchain protocol, thus any malfunction, unintended function, unexpected operation or Blockchain attack may cause malfunction or malfunction unexpectedly or unintentionally.\u003Cbr\u003E 8.4. You acknowledge and agree that Cointrade Crypto Exchange has no control over encryption network and understands all risks associated with the use of any network encryption assets, and that the Cointrade Crypto Exchange is not responsible for any damages that occur as a result of such risks.\u003Cbr\u003E 8.5. You are fully responsible for protecting your access to the Technology Platform, your private key, passwords, and your bank account details.\u003Cbr\u003E PROTECTION OF ACTIVE CRYPTO\u003Cbr\u003E 9. We strive to protect your encryption assets, and for that, we use a variety of physical and technical measures designed to protect our systems and  your encryption assets. When you forward your encryption assets to the Account Cointrade Crypto Exchange, you entrust us and authorize us to make decisions about the security of your encryption assets.\u003Cbr\u003E NOTIFICATIONS\u003Cbr\u003E 10. You agree and agree to electronically receive all Communications, which Cointrade Crypto Exchange is willing to do. You agree that Cointrade Crypto Exchange can make these Communications by posting them on the Platform.\u003Cbr\u003E 10.1. It is your responsibility to keep your e-mail address registered in the Cointrade Crypto Exchange updated so we can communicate with you   electronically. You understand and agree that if Cointrade Crypto Exchange  send an electronic communication but you do not receive it because your email address is out of date, blocked by your service provider, or if you  unable to receive electronic communications, Cointrade Crypto Exchange will consider how the communication was carried out. You waive your right to plead  ignorance.\u003Cbr\u003E 10.2. If you use a spam filter that blocks or redirects mail from senders not listed in your contact list, you must add Cointrade Crypto Exchange so that you can receive the Communications.\u003Cbr\u003E 10.3. If the electronic correspondence sent to you by Cointrade Crypto Exchange, Cointrade Crypto Exchange may consider that your account is inactive, and you may not be able to complete any transaction through Platform until we receive a valid email address from you.\u003Cbr\u003E 10.4. If you have not logged in to your account on the site for an uninterrupted period of  two years, Cointrade Crypto Exchange reserves the right to consider that all and  any property you hold on the site bandoned,   immediately lost and confiscated by Cointrade Crypto Exchange.\u003Cbr\u003E 10.5. Any benefit granted to any user of Cointrade Crypto Exchange, shall be considered as mere liberality on the part of the latter and shall not affect the other  Cointrade Crypto Exchange users.\u003Cbr\u003E SPECIAL CONDITIONS \u003Cbr\u003E 11. At any time and in our sole discretion, we may impose limits on the amount Transfer permitted by the Platform or impose any other conditions or conditions restrictions on the use of the Platform without prior notice.\u003Cbr\u003E 12. We may, at our sole discretion, without your acceptance, with or without notice prior and at any time, modify or discontinue, temporarily or permanently, any part of our Services.\u003Cbr\u003E 13. You can only cancel a Transfer request that has already been initiated through the Platform if such cancellation occurs before Cointrade Crypto Exchange runs  the transfer. Once your transfer request has been executed, you may not change, withdraw, or cancel your authorization. If an order of trading has been partially completed, you can cancel the remaining unfinished,  unless the request relates to a market rate. We reserve the right to right to refuse any cancellation request associated with the market rate of a order after you have sent such a request. Although we sole criterion, to reverse a negotiation under certain extraordinary conditions, the  user has no right to reverse any trading. \u003Cbr\u003E 14. If you have insufficient cryptographic assets in your account Cointrade Crypto Exchange to complete a transfer through the platform  technology, we may cancel the entire order or fulfill a partial order using the number of cryptographic assets currently available in your Cointrade account Crypto Exchange, less any fees due to Cointrade Crypto Exchange on  as a result of our execution of the Transfers.\u003Cbr\u003E 15. It is your responsibility to check which taxes, if any, Transfers that you conclude through the Platform and are your responsibility to inform and remit the correct tax to the appropriate tax authority.\u003Cbr\u003E You agree that Cointrade Crypto Exchange is not responsible for determining whether taxes apply to your transfers or for collecting, reporting, holding or remitting any taxes arising from any Transactions and Transfers and does not as your tax agent. \u003Cbr\u003E 16. Cointrade Crypto Exchange has exclusive rights, including all intellectual property rights over Comments. Any Feedback you  send is not confidential and will become the exclusive property of Cointrade Crypto Exchange. We will have the right to unrestricted use and disclosure of such Feedback for  any purpose, commercial or otherwise, without recognition or compensation to you.\u003Cbr\u003EYou waive any rights you may have about the Feedback. Do not do Comments if you expect to be paid or wish to continue owning or claiming  rights over it; your idea might be great, but maybe we already had the same idea  or a similar idea and we do not want disputes. We also have the right to disclose your identity to any third party claiming that the content posted by you constitutes an infringement of their intellectual property rights or of their right to privacy. We have the right to remove any post you post on our site if, in our opinion, it is not in compliance with the content standards established.\u003Cbr\u003E SUSPENSION OR TERMINATION OF YOUR COINTRADE CRYPTO ACCOUNT  EXCHANGE \u003Cbr\u003E 17. In case of violation of the Terms or any other event that we consider necessary, including, without limitation, market disruption and / or  Greater, we may, in our sole discretion and without your acceptance, with or without notice  previous \u003Cbr\u003E 17.1. suspend your access to all or part of our Services; or \u003Cbr\u003E 17.2. prevent you from completing any actions through the Platform, including the closing of any open trading order. If the transfer is  You acknowledge that the prevailing market rates may differ from the rates available prior to such event; or \u003Cbr\u003E 17.3. terminate your access to the Services, delete or deactivate your Crypto Cointrade Account Exchange and all related information and files in this account.\u003Cbr\u003E 18. In the event of termination, Cointrade Crypto Exchange will return any assets stored in your account on the platform, discounting the amounts due to the Cointrade Crypto Exchange, unless you have committed fraud, negligence or other improper conduct.\u003Cbr\u003E GUARANTEES AND RESPONSIBILITIES \u003Cbr\u003E 19. You disclaim all warranties of any kind, express or implied, including the information, content and materials contained in our services.\u003Cbr\u003E 20. You acknowledge that the information you store or transfer through our services may be lost, corrupted or temporarily become unavailable due to various causes, including software failures, third party protocol, internet interruptions, force majeure events or other disasters, scheduled or unscheduled maintenance or other causes inside or outside of our control.\u003Cbr\u003E 21. Except as otherwise required by law, under no circumstances shall Cointrade Crypto Exchange, its  officers, employees or agents shall be liable for any direct or indirect damages indirect damages of any kind, including, loss of use, loss of profits or loss of data,  related to the use or inability to use our services or the IP of the Cointrade Crypto Exchange, including any damages caused by the trust of  any information obtained by Cointrade Crypto Exchange or  arising from errors, omissions, interruptions, deletion of files or emails, errors, defects, viruses, delays in operation or transmission, or any performance failure, resulting from or not a force majeure event, communications failure, theft, destruction or unauthorized access to Cointrade's records, programs or services Crypto Exchange. \u003Cbr\u003E 22. Cointrade Crypto Exchange will not be responsible for \u003Cbr\u003E 22.1. any inaccuracy, error, delay or omission of any information, as well as the transmission or delivery of information; \u003Cbr\u003E 22.2. any loss or damage resulting from an Event of Force Majeure.\u003Cbr\u003E 23. We strive to protect our users from fraudulent and  schemes in the sphere of cryptographic assets. It is possible that some cryptographic assets have the purpose of illegally confiscating the property or are considered fraud, schemes or any other activity, recognized by the laws as illegal and / or incompatible with legal requirements. We reserve the right to prohibit and discontinue any transactions on our Platform with this encryption feature in our sole discretion, without any prior notice to you and without the publication of the reason for such a decision, wherever it comes to our attention.\u003Cbr\u003E 24. We follow the best practices for deciding whether the encryption asset is secure or do not. However, we do not give any guarantee and / or investment, financial, legal or  any other professional advice, stating that any encryption asset   available through our Platform is safe.\u003Cbr\u003EMISCELLANEOUS\u003Cbr\u003E 25. In the event of any conflict between these Terms and any other agreement you  Cointrade Crypto Exchange, these terms will prevail, unless  have been expressly identified and declared as canceled by the other   contract\u003Cbr\u003E 26. We reserve the right to make changes or modifications to these Terms of  from time to time, at our sole discretion, at which time we will provide  notices about such changes, either by email, or by notice on the homepage of the Site. The  Altered terms will be deemed effective immediately upon User continuing to  to use our Services after Cointrade Crypto Exchange warns of such  changes or publish a new version of the Terms on the Site.\u003Cbr\u003E 27. Any changed Terms will apply to the Services after they become effective. If you do not agree to any amended Terms, you must discontinue use of our Services and contact us to terminate your account.\u003Cbr\u003E 28. Our failure or delay in the exercise of any right, power or privilege under these  Terms should not work as a waiver of it. \u003Cbr\u003E 29. The invalidity or ineffectiveness of any provision contained in this Terms shall not affect  the validity or feasibility of the others, which shall remain in full force and effect  effect.\u003Cbr\u003E 30. You may not assign or transfer any of your rights or obligations under these Terms without prior written consent of Cointrade Crypto Exchange, including by law or in connection with any change of control. A Cointrade Crypto Exchange may assign or transfer any or all of its rights under these Terms, in whole or in part, without obtaining your consent or approval.\u003Cbr\u003EREGISTRATION OF AN ACCOUNT IN COINTRADE CRYPTO EXCHANGE \u003Cbr\u003E 31. You need to create an account at Cointrade Crypto Exchange to use our  Platform in the correct order and with all its functionality, enter a valid email and password. \u003Cbr\u003E 32. The KYC procedure may be required at any time if  by the competent authorities. \u003Cbr\u003E 33. When you create a Cointrade Crypto Exchange account, you are committed to \u003Cbr\u003E 33.1. create a strong password that you do not use for other sites, online or offline services; \u003Cbr\u003E 33.2. maintain the security of your Cointrade Crypto Exchange account by protecting your  password and restricting access to your Cointrade Crypto Exchange account; \u003Cbr\u003E 33.3. notify us immediately if it discovers or suspects any breach of security related to your Cointrade Crypto Exchange account  \u003Cbr\u003E 33.4. assume responsibility for all activities that occur under your Account Cointrade Crypto Exchange and accept all risks of any authorized access or  not authorized to your Cointrade Crypto Exchange Account, to the maximum extent permitted   by law. \u003Cbr\u003E DEPOSIT AND WITHDRAWAL OF ASSETS IN COINTRADE CRYPTO ACCOUNT EXCHANGE \u003Cbr\u003E 34. Our Platform allows Users to deposit in FIAT orcryptographic assets for the Crypto Exchange Cointrade Account, or through the third-party service, which the user declares to be aware of   which are only service providers. \u003Cbr\u003E 34.1. Cointrade Crypto Exchange is not responsible for problems occurring in the ticketing through partner; \u003Cbr\u003E 34.2. Tickets will be issued with the D + 1 deadline.\u003Cbr\u003E 35. Any fee charged by partners will be passed directly to the user.\u003Cbr\u003E 36. When requesting the deposit of any amount for the platform, a new value plus cents, which will identify your deposit at that time.\u003Cbr\u003E If it is generated, the use of cents will be mandatory. Any error concerning the new value added plus cents will make it impossible to identify your deposit. Case  occurs, the user must prove that he was the depositor, through a letter from the bank  responsible for the deposit, to enable the attempt to recover. \u003Cbr\u003E 37. You warrant and hold Cointrade Crypto Exchange harmless from any claims, and damages, whether direct, indirect, consequential or special, or any other damages of any kind, including, loss of use, loss of profits or loss of  originated or in any way related to your deposit or transfer requested.\u003Cbr\u003E 38. You understand and acknowledge that an address to receive an encrypted asset will be automatically created as soon as you request the transfer of the Deposit, and   before any encrypted asset can be sent to your Cointrade Account  Crypto Exchange, you must fully and irrevocably authorize its creation.\u003Cbr\u003E 39. When you request that encryption assets be deposited or removed from your  account, you authorize Cointrade Crypto Exchange to perform this transfer through  of the Platform.\u003Cbr\u003E 40. You are solely responsible for using the third-party service and you agree to comply with  all terms and conditions applicable to them.\u003Cbr\u003E 40.1. Each currency has its own particularity, which the user is solely responsible for  Cointrade Crypto Exchange from any liability for non-compliance with such particularities.\u003Cbr\u003E 41. In some cases, the outsourced service may reject your encryption  suspended, Transfer of Deposit or Withdrawal of your  encryption or does not support Transfer, or may be unavailable. Do you agree  which will not hold Cointrade Crypto Exchange responsible for any claims,and damages, whether direct, indirect, consequential or special, or any other damages of any kind, including, loss of use, loss of profits or losses of  data, arising out of or in any way connected with such rejections or suspensions of  deposit or withdrawal.\u003Cbr\u003E 42. Subject to the terms and conditions of these Terms, we will commercially reasonable to register all Transfers on an immediate basis as soon as possible. However, the time associated with Deposit or Withdrawal of assets encryption depends, inter alia, on the performance of third-party services and we do not guarantee that the encryption assets will be Deposited or Withdrawn in period of time. You understand and acknowledge that all delays  are possible; you warrant and release Cointrade Crypto Exchange from any claims, demands and damages, whether direct, indirect, consequential or special, or any other damages of any kind, including, loss of use, loss of profits or loss of data, arising out of or in any way related to the delay of transfer, whether arising from our failure or not.\u003Cbr\u003E TRADING CRYPTO ASSETS \u003Cbr\u003E 43. Crypto asset trade occurs among users. \u003Cbr\u003E 44. When you send a trading order through the Platform, you authorize the Cointrade Crypto Exchange on \u003Cbr\u003E 44.1. register a transfer of your cryptographic assets from / to / into your account Cointrade Crypto Exchange. \u003Cbr\u003E 44.2. when applicable, reserve your encryption assets in your Cointrade account Crypto Exchange under such a trade order. \u003Cbr\u003E 44.3. and charge any applicable fees for such registration. \u003Cbr\u003E 45. You acknowledge and agree that in relation to your trading activity, our Platform \u003Cbr\u003E 45.1 is not acting as your broker, intermediary, agent or consultant or any fiduciary capacity; \u003Cbr\u003E 45.2. not acting as part of the transfer of a particular asset encrypted.\u003Cbr\u003E 46. ​​Each placed order of transaction creates different market exchange rates.\u003Cbr\u003E You acknowledge and agree that the rate information made available through the Platform may differ from current rates made available from other sources outside the Platform. \u003Cbr\u003E 47. Particularly during periods of high volume, lack of liquidity,or volatility in the market for any encrypted asset, the actual the market in which a market transaction is carried out may be different from the platform indicated at the time of execution of its Transaction. commercial. You understand that we are not responsible for such rate fluctuations.\u003Cbr\u003E 48. The tariffs made available through the Platform should not be considered as an investment or financial advice, or referred to as such, and can not be used as the basis for investment strategy. \u003Cbr\u003E COINTRADE CRYPTO EXCHANGE RATES \u003Cbr\u003E 49. The first 20,000 (twenty thousand) enrolled in the Platform will be exempt from payment until December 2018, after which the promotion and fees will end. will be charged for transactions completed through the Platform. \u003Cbr\u003E 50. You agree to pay the fees for Transfers completed through the Platform, as defined by the Fees and Limits, which may be changed  periodically. The changes in the Fees are effective as of the date indicated in the revised Tariffs and Limits, and will be applied prospectively to the any Transfers occurring after the date of such revised Fees\u003Cbr\u003E. 51. Payment of fees. You authorize us, or our payment processor  designated, to collect or deduct the cryptographic assets from your Cointrade Crypto account Exchange for any fees due in connection with the negotiations concluded through of the Platform.\u003Cbr\u003E COPYRIGHT AND OTHER PROPRIETARY RIGHTS INTELECTUAL.\u003Cbr\u003E 52. Cointrade Crypto Exchange and the logo, trade names, brands nominative marks and design marks are trademarks of Dinamiam S / A. You agree not to appropriate, copy, display or use the Crypto Cointrade Marks Exchange or other content without prior express written permission to do so.\u003Cbr\u003E THIRD PARTY CONTENT \u003Cbr\u003E 53. By using our Platform, you can view third-party content. We do not  control, endorse or adopt (unless expressly stated by us) any Third Party Content and we shall have no responsibility for the Content of Third Parties, including, without limitation, materials that may be misleading, incomplete,\u003Cbr\u003E misleading, offensive, indecent or otherwise objectionable. In addition, their business or correspondence with such third parties are solely between you and the 3rd. We are not responsible for any loss or damage of any kind incurred as a result of such negotiations, and you understand that your use of Content and your interactions with third parties are your responsibility. \u003Cbr\u003E 54. Cointrade Crypto Exchange is against any illegal activity, drug trafficking, human beings, organs and any other illegal trafficking, poaching, pornography, trade in arms, terrorism and criminal financing, corruption, bribery and laundering of money.\u003Cbr\u003E"},"markets":{"market_list":{"all":"All Market","brl":"BRL Market","btc":"BTC Market","bch":"BCH Market","btg":"BTG Market","dash":"DASH Market","eth":"ETH Market","zec":"ZEC Market","dgb":"DGB Market","xrp":"XRP Market","smart":"Smart Market","iota":"IOTA Market","ltc":"LTC Market","zcr":"ZCR Market","tusd":"TUSD Market","xem":"XEM Market","rbtc":"RBTC Market","rif":"RIF Market","xar":"XAR Market"}},"markets_overview":{"market_depth":"Market Depth"}}};
I18n.locale = 'en';


