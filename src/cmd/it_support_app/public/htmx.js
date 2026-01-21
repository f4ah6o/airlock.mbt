class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
const moonbitlang$core$builtin$$random_seed = () => {
  if (globalThis.crypto?.getRandomValues) {
    const array = new Uint32Array(1);
    globalThis.crypto.getRandomValues(array);
    return array[0] | 0; // Convert to signed 32
  } else {
    return Math.floor(Math.random() * 0x100000000) | 0; // Fallback to Math.random
  }
};
function Result$Err$0$(param0) {
  this._0 = param0;
}
Result$Err$0$.prototype.$tag = 0;
function Result$Ok$0$(param0) {
  this._0 = param0;
}
Result$Ok$0$.prototype.$tag = 1;
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds = { $tag: 1 };
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex = { $tag: 0 };
const moonbitlang$core$builtin$$int_to_string_js = (x, radix) => {
  return x.toString(radix);
};
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
const moonbitlang$core$builtin$$JSArray$push = (arr, val) => { arr.push(val); };
const mizchi$js$core$$Any$_call = (obj, key, args) => obj[key](...args);
const mizchi$js$core$$is_nullish = (v) => v == null;
const mizchi$js$core$$Any$_set = (obj, key, value) => { obj[key] = value };
const mizchi$js$core$$new_object = () => ({});
const mizchi$js$core$$from_entries = (entries) => Object.fromEntries(entries.map(e => [e._0, e._1]));
const mizchi$js$core$$array_from = (v) => Array.from(v);
const Option$None$1$ = { $tag: 0 };
function Option$Some$1$(param0) {
  this._0 = param0;
}
Option$Some$1$.prototype.$tag = 1;
const mizchi$js$web$event$$Event$preventDefault = (self) => self.preventDefault();
const mizchi$js$browser$dom$$Element$tagName = (self) => self.tagName;
const mizchi$js$browser$dom$$document = () => document;
const f4ah6o$htmx$src$htmx$$get_expression_vars_inner = (elt, event) => {
  // Unwrap MoonBit Option type for elt
  const element = (elt && elt.$tag === 1) ? elt._0 : null;

  // Helper to get attribute value (checks both hx-* and data-hx-*)
  const getAttributeValue = (el, attr) => {
    if (!el) return null;
    return el.getAttribute(attr) || el.getAttribute('data-' + attr);
  };

  // Parse and evaluate hx-vars/hx-vals attribute value
  const parseVarsValue = (elt, attrValue, evaluate) => {
    let str = attrValue ? attrValue.trim() : '';
    let evaluateValue = evaluate;

    // Check for 'unset' keyword
    if (str === 'unset') {
      return null;
    }

    // Check for javascript: or js: prefix
    if (str.indexOf('javascript:') === 0) {
      str = str.slice(11);
      evaluateValue = true;
    } else if (str.indexOf('js:') === 0) {
      str = str.slice(3);
      evaluateValue = true;
    }

    // Wrap in braces if not already present
    if (str.indexOf('{') !== 0) {
      str = '{' + str + '}';
    }

    let varsValues;
    if (evaluateValue) {
      // Check if allowEval is enabled
      const allowEval = window.htmx && window.htmx.config && window.htmx.config.allowEval !== false;
      if (!allowEval) {
        // Trigger evalDisallowedError event
        const errorEvt = new CustomEvent('htmx:evalDisallowedError', {
          bubbles: true,
          cancelable: true,
          detail: { source: 'hx-vars' }
        });
        elt.dispatchEvent(errorEvt);
        return {};
      }
      try {
        if (event) {
          // Unwrap event Option if needed
          const evt = (event && event.$tag === 1) ? event._0 : event;
          varsValues = new Function('event', 'return (' + str + ')').call(elt, evt);
        } else {
          varsValues = new Function('return (' + str + ')').call(elt);
        }
      } catch (e) {
        console.error('htmx.mbt: Error evaluating vars:', e);
        return {};
      }
    } else {
      try {
        varsValues = JSON.parse(str);
      } catch (e) {
        console.error('htmx.mbt: Error parsing vars JSON:', e);
        return {};
      }
    }

    return varsValues || {};
  };

  // Collect values from hx-vars or hx-vals attribute on element and its parents
  const getValuesForElement = (elt, attr, evalAsDefault, values, event) => {
    if (values == null) {
      values = {};
    }
    if (elt == null) {
      return values;
    }
    const attributeValue = getAttributeValue(elt, attr);
    if (attributeValue) {
      let str = attributeValue.trim();
      let evaluateValue = evalAsDefault;
      if (str === 'unset') {
        return null;
      }
      if (str.indexOf('javascript:') === 0) {
        str = str.slice(11);
        evaluateValue = true;
      } else if (str.indexOf('js:') === 0) {
        str = str.slice(3);
        evaluateValue = true;
      }
      if (str.indexOf('{') !== 0) {
        str = '{' + str + '}';
      }
      let varsValues;
      if (evaluateValue) {
        varsValues = parseVarsValue(elt, str, true);
      } else {
        varsValues = parseVarsValue(elt, str, false);
      }
      for (const key in varsValues) {
        if (varsValues.hasOwnProperty(key)) {
          if (values[key] == null) {
            values[key] = varsValues[key];
          }
        }
      }
    }
    // Continue to parent
    const parent = elt.parentElement;
    if (parent) {
      return getValuesForElement(parent, attr, evalAsDefault, values, event);
    }
    return values;
  };

  // Get both hx-vars and hx-vals
  let vars = {};
  let vals = {};

  if (element) {
    vars = getValuesForElement(element, 'hx-vars', true, {}, event) || {};
    vals = getValuesForElement(element, 'hx-vals', false, {}, event) || {};
  }

  // Merge vars and vals, with vals taking precedence
  const result = { ...vars, ...vals };

  // Convert to MoonBit Map format
  const entries = Object.entries(result);
  const buf = [];
  for (const [k, v] of entries) {
    buf.push({ _0: k, _1: String(v) });
  }
  return { buf: buf, start: 0, end: buf.length };
};
const f4ah6o$htmx$src$htmx$$map_to_any = (m) => {
  // MoonBit Map has { buf: [{_0: key, _1: value}, ...], start, end } structure
  return m;  // Return the Map directly, it's already in JS format
};
const f4ah6o$htmx$src$htmx$$form_report_validity = (form) => form.reportValidity ? form.reportValidity() : true;
const f4ah6o$htmx$src$htmx$$element_check_validity = (el) => el.checkValidity ? el.checkValidity() : true;
const f4ah6o$htmx$src$htmx$$has_novalidate = (form) => form.hasAttribute('novalidate');
const f4ah6o$htmx$src$htmx$$has_hx_validate = (el) => el.hasAttribute('hx-validate') || el.hasAttribute('data-hx-validate');
const f4ah6o$htmx$src$htmx$$dispatch_validate_events = (form) => {
  const inputs = form.querySelectorAll('input, select, textarea');
  for (let i = 0; i < inputs.length; i++) {
    const evt = new CustomEvent('htmx:validation:validate', { bubbles: true, cancelable: true });
    inputs[i].dispatchEvent(evt);
  }
};
const f4ah6o$htmx$src$htmx$$dispatch_validate_event = (el) => {
  const evt = new CustomEvent('htmx:validation:validate', { bubbles: true, cancelable: true });
  el.dispatchEvent(evt);
};
const f4ah6o$htmx$src$htmx$$get_invalid_elements = (form) => {
  if (!form.querySelectorAll) return [];
  const invalids = [];
  const inputs = form.querySelectorAll('input, select, textarea');
  for (let i = 0; i < inputs.length; i++) {
    if (inputs[i].checkValidity && !inputs[i].checkValidity()) {
      invalids.push(inputs[i]);
    }
  }
  return invalids;
};
const f4ah6o$htmx$src$htmx$$dispatch_validation_failed_event = (target, detail) => {
  const evt = new CustomEvent('htmx:validation:failed', {
    bubbles: true,
    cancelable: true,
    detail: detail
  });
  return target.dispatchEvent(evt);
};
const f4ah6o$htmx$src$htmx$$dispatch_validation_halted = (form, errors) => {
  const evt = new CustomEvent('htmx:validation:halted', {
    bubbles: true,
    cancelable: true,
    detail: { errors: errors }
  });
  form.dispatchEvent(evt);
};
const f4ah6o$htmx$src$htmx$$focus_element = (el) => { if (el.focus) el.focus(); };
const f4ah6o$htmx$src$htmx$$create_errors_array = (invalids) => {
  return invalids.map(el => ({
    elt: el,
    message: el.validationMessage || '',
    validity: el.validity || {}
  }));
};
const f4ah6o$htmx$src$htmx$$get_config_report_validity = () => window.htmx && window.htmx.config && window.htmx.config.reportValidityOfForms === true;
const f4ah6o$htmx$src$htmx$$has_formnovalidate = (el) => { try { return el && (el.hasAttribute('formnovalidate') || el.formnovalidate === true); } catch(e) { return false; } };
const f4ah6o$htmx$src$htmx$$request_async_callback = (url, method_str, trigger_element, headers_map, callback) => {
  const xhr = new XMLHttpRequest();
  xhr.open(method_str, url, true);

  // Set headers from map
  const headers = headers_map;
  for (const [key, value] of Object.entries(headers)) {
    xhr.setRequestHeader(key, value);
  }

  xhr.onload = function() {
    if (xhr.status >= 200 && xhr.status < 300) {
      callback(xhr.responseText || '');
    } else {
      callback(null);
    }
  };

  xhr.onerror = function() {
    callback(null);
  };

  xhr.send();
};
const f4ah6o$htmx$src$htmx$$request_with_form_async_callback = (url, method_str, form_data_any, trigger_element, headers_map, callback) => {
  const xhr = new XMLHttpRequest();
  xhr.open(method_str, url, true);

  // Set headers from map
  const headers = headers_map;
  for (const [key, value] of Object.entries(headers)) {
    xhr.setRequestHeader(key, value);
  }

  xhr.onload = function() {
    if (xhr.status >= 200 && xhr.status < 300) {
      callback(xhr.responseText || '');
    } else {
      callback(null);
    }
  };

  xhr.onerror = function() {
    callback(null);
  };

  // Convert FormData to URL-encoded string for Sinon compatibility
  let body = form_data_any;
  if (form_data_any && typeof form_data_any.append === 'function') {
    // This is a FormData object, convert to URL-encoded string
    const params = [];
    for (const [key, value] of form_data_any.entries()) {
      params.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
    }
    body = params.join('&');
  }

  xhr.send(body);
};
const f4ah6o$htmx$src$htmx$$map_to_js_object = (m) => {
  const obj = {};
  // MoonBit Map has { buf: [{_0: key, _1: value}, ...], start, end } structure
  if (m && m.buf) {
    for (let i = m.start || 0; i < (m.end || m.buf.length); i++) {
      const entry = m.buf[i];
      if (entry && entry._0 !== undefined) {
        obj[entry._0] = entry._1;
      }
    }
  }
  return obj;
};
const f4ah6o$htmx$src$htmx$$log_debug = (msg) => console.log("[htmx.mbt DEBUG] " + msg);
const f4ah6o$htmx$src$htmx$$append_vars_to_form_data = (form_data, vars_map) => {
  // vars_map is a MoonBit Map with { buf: [{_0: key, _1: value}, ...], start, end }
  if (vars_map && vars_map.buf) {
    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
      const entry = vars_map.buf[i];
      if (entry && entry._0 !== undefined) {
        const key = entry._0;
        const value = entry._1;
        // Remove existing value (vars override form values)
        form_data.delete(key);
        // Add the vars value
        form_data.append(key, value);
      }
    }
  }
};
const f4ah6o$htmx$src$htmx$$append_vars_to_url = (url, vars_map) => {
  // vars_map is a MoonBit Map with { buf: [{_0: key, _1: value}, ...], start, end }
  let params = [];
  if (vars_map && vars_map.buf) {
    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
      const entry = vars_map.buf[i];
      if (entry && entry._0 !== undefined) {
        const key = encodeURIComponent(entry._0);
        const value = encodeURIComponent(entry._1);
        params.push(key + '=' + value);
      }
    }
  }
  if (params.length === 0) return url;
  const separator = url.includes('?') ? '&' : '?';
  return url + separator + params.join('&');
};
const f4ah6o$htmx$src$htmx$$get_element_checked = (el) => !!el.checked;
const f4ah6o$htmx$src$htmx$$get_element_value = (el) => el.value || "";
const f4ah6o$htmx$src$htmx$$create_form_data_from_inputs_and_vars = (element, vars_map) => {
  const fd = new FormData();

  // Collect input values from element
  // First, check if element itself is an input/select/textarea
  const tag = element.tagName.toUpperCase();
  if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') {
    const name = element.getAttribute('name');
    if (name && name.length > 0) {
      let value = null;
      if (tag === 'INPUT') {
        const type = element.getAttribute('type') || 'text';
        if (type === 'checkbox' || type === 'radio') {
          if (element.checked) {
            value = element.value || 'on';
          }
        } else if (type !== 'file') {
          value = element.value || '';
        }
      } else {
        value = element.value || '';
      }
      if (value !== null) {
        fd.append(name, value);
      }
    }
  }

  // Then collect from child elements
  const inputs = element.querySelectorAll('input, select, textarea');
  for (const input of inputs) {
    const name = input.getAttribute('name');
    if (name && name.length > 0) {
      let value = null;
      const tag = input.tagName.toUpperCase();
      if (tag === 'INPUT') {
        const type = input.getAttribute('type') || 'text';
        if (type === 'checkbox' || type === 'radio') {
          if (input.checked) {
            value = input.value || 'on';
          }
        } else if (type === 'file') {
          // Skip file inputs
          continue;
        } else {
          value = input.value || '';
        }
      } else if (tag === 'SELECT') {
        value = input.value || '';
      } else if (tag === 'TEXTAREA') {
        value = input.value || '';
      }
      if (value !== null) {
        fd.append(name, value);
      }
    }
  }

  // Add vars values (vars override input values)
  if (vars_map && vars_map.buf) {
    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
      const entry = vars_map.buf[i];
      if (entry && entry._0 !== undefined) {
        const key = entry._0;
        const value = entry._1;
        // Remove existing value (vars override input values)
        fd.delete(key);
        // Add the vars value
        fd.append(key, value);
      }
    }
  }

  return fd;
};
const f4ah6o$htmx$src$htmx$$create_response_callback = (element, target, swap_style_str, url, disabled_elements, indicator_elements) => {
  return function(responseText) {
    // Hide indicators after request
    if (indicator_elements.length > 0) {
      for (const el of indicator_elements) {
        const key = "htmx-internal-data";
        const data = el[key];
        if (data) {
          data.indicatorCount = (data.indicatorCount || 1) - 1;
        }
        const count = data ? (data.indicatorCount || 0) : 0;
        if (count === 0) {
          el.classList.remove("htmx-request");
        }
      }
    }

    // Re-enable disabled elements after request
    if (disabled_elements.length > 0) {
      for (const el of disabled_elements) {
        const key = "htmx-internal-data";
        const data = el[key];
        if (data) {
          data.requestCount = (data.requestCount || 1) - 1;
        }
        const count = data ? (data.requestCount || 0) : 0;
        if (count === 0) {
          el.removeAttribute("disabled");
        }
      }
    }

    // Swap content if we got a response
    if (responseText !== null) {
      const htmx = window.htmx || {};
      const config = htmx.config || {};
      const selectVal = element.getAttribute("hx-select") || element.getAttribute("data-hx-select");
      const swapSpecFn = htmx._ ? htmx._('getSwapSpecification') : null;
      const swapSpec = swapSpecFn ? swapSpecFn(element) : null;
      const defaultSwapStyle = typeof config.defaultSwapStyle === 'string'
        ? config.defaultSwapStyle
        : 'innerHTML';
      // Use the passed swap_style_str (with inheritance support) as priority
      const swapStyle = swap_style_str && typeof swap_style_str === 'string'
        ? swap_style_str
        : (swapSpec && typeof swapSpec.swapStyle === 'string'
          ? swapSpec.swapStyle
          : defaultSwapStyle);
      const swapDelay = swapSpec && typeof swapSpec.swapDelay === 'number' ? swapSpec.swapDelay : 0;
      const settleDelay = swapSpec && typeof swapSpec.settleDelay === 'number'
        ? swapSpec.settleDelay
        : (typeof config.defaultSettleDelay === 'number' ? config.defaultSettleDelay : 0);
      const transition = swapSpec && swapSpec.transition === true;
      const scrollSpec = swapSpec ? swapSpec.scroll : null;
      const showSpec = swapSpec ? swapSpec.show : null;
      const allowNestedOobSwaps = config.allowNestedOobSwaps !== false;
      const knownSwapStyles = new Set([
        'innerHTML',
        'outerHTML',
        'beforebegin',
        'afterbegin',
        'beforeend',
        'afterend',
        'delete',
        'none',
        'morph',
        'textContent'
      ]);
      const resolvedStyle = knownSwapStyles.has(swapStyle) ? swapStyle : defaultSwapStyle;
      const parser = new DOMParser();
      let finalContent = responseText;
      let oobDoc = null;
      if (resolvedStyle !== 'textContent') {
        let doc = parser.parseFromString(responseText, 'text/html');
        if (selectVal) {
          const selected = doc.querySelector(selectVal);
          finalContent = selected ? selected.outerHTML : '';
          doc = parser.parseFromString(finalContent, 'text/html');
        } else {
          finalContent = doc.body.innerHTML;
        }
        oobDoc = doc;
        const rootNode = element && element.getRootNode ? element.getRootNode() : document;
        const localRoot = rootNode && rootNode.querySelectorAll ? rootNode : document;
        const stripOobAttrs = (oobEl) => {
          oobEl.removeAttribute('hx-swap-oob');
          oobEl.removeAttribute('data-hx-swap-oob');
        };
        const escapeId = (id) => {
          if (!id) return null;
          if (window.CSS && CSS.escape) return '#' + CSS.escape(id);
          return '[id="' + String(id).replace(/"/g, '\\"') + '"]';
        };
        const normalizeOobStyle = (style) => {
          const allowed = [
            'innerHTML',
            'outerHTML',
            'beforebegin',
            'afterbegin',
            'beforeend',
            'afterend',
            'delete',
            'none',
            'morph'
          ];
          return allowed.includes(style) ? style : 'innerHTML';
        };
        const parseOobSpec = (oobEl) => {
          const rawVal = oobEl.getAttribute('hx-swap-oob') || oobEl.getAttribute('data-hx-swap-oob') || 'true';
          let swap = 'innerHTML';
          let targetSelector = null;
          if (rawVal === 'true') {
            swap = 'outerHTML';
            targetSelector = escapeId(oobEl.getAttribute('id'));
          } else if (rawVal.includes(':')) {
            const parts = rawVal.split(':');
            swap = parts[0] || 'innerHTML';
            targetSelector = parts.slice(1).join(':');
          } else {
            swap = rawVal;
            targetSelector = escapeId(oobEl.getAttribute('id'));
          }
          let isGlobal = false;
          if (targetSelector) {
            const trimmed = targetSelector.trim();
            if (trimmed.startsWith('global ')) {
              isGlobal = true;
              targetSelector = trimmed.slice(7).trim();
            } else if (trimmed === 'global') {
              isGlobal = true;
              targetSelector = null;
            } else {
              targetSelector = trimmed;
            }
          }
          return { swapStyle: normalizeOobStyle(swap), targetSelector, isGlobal };
        };
        const selectTargets = (spec) => {
          if (!spec.targetSelector) return [];
          const root = spec.isGlobal ? document : localRoot;
          if (!root || !root.querySelectorAll) return [];
          try {
            return Array.from(root.querySelectorAll(spec.targetSelector));
          } catch (e) {
            return [];
          }
        };
        const applyOobSwap = (targetEl, spec, innerHtml, outerHtml) => {
          switch (spec.swapStyle) {
            case 'innerHTML':
              targetEl.innerHTML = innerHtml;
              break;
            case 'outerHTML':
              targetEl.outerHTML = outerHtml;
              break;
            case 'beforebegin':
              targetEl.insertAdjacentHTML('beforebegin', outerHtml);
              break;
            case 'afterbegin':
              targetEl.insertAdjacentHTML('afterbegin', innerHtml);
              break;
            case 'beforeend':
              targetEl.insertAdjacentHTML('beforeend', innerHtml);
              break;
            case 'afterend':
              targetEl.insertAdjacentHTML('afterend', outerHtml);
              break;
            case 'delete':
              targetEl.remove();
              break;
            case 'none':
              break;
            default:
              targetEl.innerHTML = innerHtml;
              break;
          }
        };
        const handleOobElement = (oobEl, fromTemplate) => {
          const parent = oobEl.parentElement;
          const isNested = !fromTemplate && !allowNestedOobSwaps &&
            parent && parent !== oobDoc.body && parent.tagName !== 'BODY';
          if (isNested) {
            stripOobAttrs(oobEl);
            return;
          }
          const spec = parseOobSpec(oobEl);
          const targets = selectTargets(spec);
          if (spec.swapStyle === 'delete') {
            for (const targetEl of targets) {
              targetEl.remove();
            }
            oobEl.remove();
            return;
          }
          stripOobAttrs(oobEl);
          if (targets.length === 0) {
            if (spec.targetSelector) {
              const evt = new CustomEvent('htmx:oobErrorNoTarget', {
                bubbles: true,
                cancelable: true,
                detail: { content: oobEl }
              });
              document.body.dispatchEvent(evt);
            }
            oobEl.remove();
            return;
          }
          const innerHtml = oobEl.innerHTML;
          const outerHtml = oobEl.outerHTML;
          for (const targetEl of targets) {
            applyOobSwap(targetEl, spec, innerHtml, outerHtml);
          }
          oobEl.remove();
        };
        const templates = oobDoc.querySelectorAll('template');
        for (const template of templates) {
          const content = template.content;
          if (!content) {
            continue;
          }
          const nestedOobs = content.querySelectorAll('[hx-swap-oob], [data-hx-swap-oob]');
          if (nestedOobs.length === 0) {
            continue;
          }
          for (const oobEl of nestedOobs) {
            handleOobElement(oobEl, true);
          }
          template.remove();
        }
        const oobElements = oobDoc.querySelectorAll('[hx-swap-oob], [data-hx-swap-oob]');
        for (const oobEl of oobElements) {
          handleOobElement(oobEl, false);
        }
        finalContent = oobDoc.body.innerHTML;
      }
      const dispatchSwapError = (err) => {
        const evt = new CustomEvent('htmx:swapError', {
          bubbles: true,
          cancelable: true,
          detail: { error: err }
        });
        document.body.dispatchEvent(evt);
      };
      const applySwap = (content) => {
        switch (resolvedStyle) {
          case 'innerHTML':
            target.innerHTML = content;
            break;
          case 'outerHTML':
            if (target.tagName && target.tagName.toUpperCase() === 'BODY') {
              target.innerHTML = content;
            } else {
              target.outerHTML = content;
            }
            break;
          case 'beforebegin':
            target.insertAdjacentHTML('beforebegin', content);
            break;
          case 'afterbegin':
            target.insertAdjacentHTML('afterbegin', content);
            break;
          case 'beforeend':
            target.insertAdjacentHTML('beforeend', content);
            break;
          case 'afterend':
            target.insertAdjacentHTML('afterend', content);
            break;
          case 'delete':
            target.remove();
            break;
          case 'none':
            break;
          case 'textContent':
            target.textContent = content;
            break;
          case 'morph':
            target.innerHTML = content;
            break;
          default:
            target.innerHTML = content;
            break;
        }
      };
      const resolveScrollTarget = (spec) => {
        if (!spec) return null;
        if (!spec.target || spec.target === 'window') {
          return document.body;
        }
        return document.querySelector(spec.target);
      };
      const settleActions = () => {
        if (scrollSpec && scrollSpec.direction) {
          const scrollTarget = resolveScrollTarget(scrollSpec);
          if (scrollTarget) {
            if (scrollSpec.direction === 'top') {
              if (scrollTarget === document.body) {
                window.scrollTo(0, 0);
              } else {
                scrollTarget.scrollTop = 0;
              }
            } else if (scrollSpec.direction === 'bottom') {
              if (scrollTarget === document.body) {
                window.scrollTo(0, document.body.scrollHeight);
              } else {
                scrollTarget.scrollTop = scrollTarget.scrollHeight;
              }
            }
          }
        }
        if (showSpec && showSpec.direction) {
          const showTarget = resolveScrollTarget(showSpec);
          if (showTarget && typeof showTarget.scrollIntoView === 'function') {
            const block = showSpec.direction === 'bottom' ? 'end' : 'start';
            showTarget.scrollIntoView({ block: block });
          }
        }
      };
      const doSwap = () => {
        try {
          if (typeof window.makeSettleInfo === 'function') {
            window.makeSettleInfo(target);
          }
          applySwap(finalContent);
        } catch (e) {
          dispatchSwapError(e);
          return;
        }
        // Evaluate inline scripts and load external scripts after swap (Issue #2, Issue #3)
        // Only executes scripts with no type or type='text/javascript'
        // Exceptions are caught to prevent breaking rendering
        if (window.htmx && window.htmx.config && window.htmx.config.allowEval !== false) {
          // Initialize internal tracking for loaded scripts to prevent duplicate execution
          if (!window.htmx._internal) window.htmx._internal = {};
          if (!window.htmx._internal.loadedScripts) window.htmx._internal.loadedScripts = new Set();
          const scripts = target.querySelectorAll('script');
          for (const script of scripts) {
            const type = script.getAttribute('type');
            if (!type || type === 'text/javascript') {
              const src = script.getAttribute('src');
              if (src) {
                // External script with src attribute (Issue #3)
                // innerHTML doesn't trigger script loading, so we need to create a new script element
                // Prevent duplicate execution by checking if script URL was already loaded
                if (window.htmx._internal.loadedScripts.has(src)) {
                  // Already loaded, remove original element to prevent duplicates
                  script.remove();
                  continue;
                }
                const newScript = document.createElement('script');
                newScript.src = src;
                // Copy necessary attributes including ID for test compatibility
                const attrsToCopy = ['id', 'nonce', 'referrerpolicy', 'type', 'async', 'defer', 'crossorigin'];
                for (const attr of attrsToCopy) {
                  if (script.hasAttribute(attr)) {
                    newScript.setAttribute(attr, script.getAttribute(attr));
                  }
                }
                // Mark as loaded (at load start time to prevent race conditions)
                window.htmx._internal.loadedScripts.add(src);
                // Replace to trigger loading
                script.replaceWith(newScript);
              } else if (script.textContent) {
                // Inline script (Issue #2)
                try {
                  (new Function(script.textContent))();
                } catch (e) {
                  console.error('htmx.mbt: Error executing script:', e);
                }
                script.remove();
              }
            }
          }
        }
        // Handle history API
        const push_val = element.getAttribute("hx-push-url") || element.getAttribute("data-hx-push-url");
        if (push_val && push_val !== "false") {
          const dest_url = push_val === "true" ? url : push_val;
          history.pushState(null, '', dest_url);
          // Save to history cache
          if (window.htmx && window.htmx._ && typeof window.htmx._ === 'function') {
            try {
              window.htmx._('saveToHistoryCache')(dest_url, target);
            } catch (e) {
              // Ignore errors
            }
          }
        }
        if (settleDelay > 0) {
          setTimeout(settleActions, settleDelay);
        } else {
          settleActions();
        }
      };
      if (swapDelay > 0 || transition) {
        setTimeout(doSwap, swapDelay);
      } else {
        doSwap();
      }
    }
  };
};
const f4ah6o$htmx$src$htmx$$inc_request_count = (el) => {
  const key = "htmx-internal-data";
  let data = el[key];
  if (!data) {
    data = {};
    el[key] = data;
  }
  data.requestCount = (data.requestCount || 0) + 1;
};
const f4ah6o$htmx$src$htmx$$set_disabled_attr = (el) => el.setAttribute("disabled", "disabled");
const f4ah6o$htmx$src$htmx$$element_matches = (el, sel) => { return el.matches(sel); };
const f4ah6o$htmx$src$htmx$$get_next_sibling = (el) => { const next = el.nextElementSibling; return next ? { $tag: 1, _0: next } : { $tag: 0 }; };
const f4ah6o$htmx$src$htmx$$get_previous_sibling = (el) => { const prev = el.previousElementSibling; return prev ? { $tag: 1, _0: prev } : { $tag: 0 }; };
const f4ah6o$htmx$src$htmx$$log_debug_attr = (msg) => console.log("[htmx.mbt ATTR DEBUG] " + msg);
const f4ah6o$htmx$src$htmx$$substring_after = (s, start) => { return s.substring(start); };
const f4ah6o$htmx$src$htmx$$trim_string = (s) => { return s.trim(); };
const f4ah6o$htmx$src$htmx$$split_by_comma = (s) => {
  return s.split(',').map(str => str.trim());
};
const f4ah6o$htmx$src$htmx$$form_data_from_element = (el) => new FormData(el);
const Option$None$2$ = { $tag: 0 };
function Option$Some$2$(param0) {
  this._0 = param0;
}
Option$Some$2$.prototype.$tag = 1;
const f4ah6o$htmx$src$htmx$$join_with_comma = (arr) => arr.filter(s => s !== "").join(", ");
const f4ah6o$htmx$src$htmx$$get_parent_element = (el) => { const parent = el.parentElement; return parent ? { $tag: 1, _0: parent } : { $tag: 0 }; };
const f4ah6o$htmx$src$htmx$$check_includes_attribute = (arr, attr) => {
  if (!arr || !Array.isArray(arr)) return false;
  return arr.includes(attr);
};
const f4ah6o$htmx$src$htmx$$check_inherits_all = (arr) => {
  if (!arr || !Array.isArray(arr)) return false;
  return arr.includes('*');
};
const f4ah6o$htmx$src$htmx$$parse_hx_inherit = (value) => {
  if (!value || value === '*') return ['*'];
  return value.split(/\s+/).filter(s => s.length > 0);
};
const f4ah6o$htmx$src$htmx$$get_disable_inheritance = () => {
  try {
    return window.htmx && window.htmx.config && window.htmx.config.disableInheritance === true;
  } catch(e) {
    return false;
  }
};
const f4ah6o$htmx$src$htmx$$add_request_class = (el) => el.classList.add("htmx-request");
const f4ah6o$htmx$src$htmx$$inc_indicator_count = (el) => {
  const key = "htmx-internal-data";
  let data = el[key];
  if (!data) {
    data = {};
    el[key] = data;
  }
  data.indicatorCount = (data.indicatorCount || 0) + 1;
};
const f4ah6o$htmx$src$htmx$$url_encode = (s) => encodeURIComponent(s);
const Option$None$3$ = { $tag: 0 };
function Option$Some$3$(param0) {
  this._0 = param0;
}
Option$Some$3$.prototype.$tag = 1;
const f4ah6o$htmx$src$htmx$$get_event_target = (evt) => {
  if (evt && typeof evt.composedPath === 'function') {
    const path = evt.composedPath();
    if (path && path.length > 0 && path[0] && path[0].nodeType === 1) {
      return path[0];
    }
  }
  return evt.target;
};
const f4ah6o$htmx$src$htmx$$is_submit_button = (el) => el && el.tagName === 'BUTTON' && (el.type === 'submit' || !el.type);
const f4ah6o$htmx$src$htmx$$find_closest_form = (el) => el.form || el.closest('form');
const f4ah6o$htmx$src$htmx$$has_containing_form = (el) => !!(el.form || el.closest('form'));
const f4ah6o$htmx$src$htmx$$get_event_submitter = (evt) => evt.submitter || null;
const f4ah6o$htmx$src$htmx$$process_load_triggers = () => {
  const doc = document;

  // Function to process a single element for load trigger
  const processElement = (el) => {
    const trigger = el.getAttribute('hx-trigger') || el.getAttribute('data-hx-trigger');
    if (trigger) {
      const parts = trigger.split(',').map(s => s.trim());
      for (const part of parts) {
        if (part === 'load' || part.startsWith('load ')) {
          // Create and dispatch a click event to trigger the request
          const event = new MouseEvent('click', { bubbles: true, cancelable: true });
          el.dispatchEvent(event);
          break;
        }
      }
    }
  };

  // Process existing elements
  const elements = doc.querySelectorAll('[hx-trigger], [data-hx-trigger]');
  for (const el of elements) {
    processElement(el);
  }

  // Set up MutationObserver to watch for new elements
  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === 1) { // Element node
          // Check the node itself
          if (node.getAttribute && (node.getAttribute('hx-trigger') || node.getAttribute('data-hx-trigger'))) {
            processElement(node);
          }
          // Check descendants
          const descendants = node.querySelectorAll('[hx-trigger], [data-hx-trigger]');
          for (const desc of descendants) {
            processElement(desc);
          }
        }
      }
    }
  });

  // Start observing the document
  observer.observe(doc.body, { childList: true, subtree: true });
};
const f4ah6o$htmx$src$htmx$$init_hx_on_delegation = (doc_target) => {
  // Common events to delegate - covers all test cases
  const commonEvents = [
    'click', 'dblclick', 'mousedown', 'mouseup', 'mouseover', 'mouseout',
    'mousemove', 'mouseenter', 'mouseleave',
    'keydown', 'keyup', 'keypress',
    'change', 'input', 'submit', 'focus', 'blur',
    'load', 'revealed',
    'htmx:config-request', 'htmx:after-request', 'htmx:before-request',
    'htmx:before-swap', 'htmx:after-swap', 'htmx:before-settle', 'htmx:after-settle',
    'htmx:validation:failed', 'htmx:validation:halted',
    'htmx:evalDisallowedError'
  ];

  // Handler function for all hx-on events
  const handleHxOn = function(evt) {
    const eventType = evt.type;
    let currentTarget = evt.target;

    // Walk up the DOM tree to find elements with hx-on attributes
    while (currentTarget && currentTarget !== document) {
      const attrs = currentTarget.attributes;
      for (let i = 0; i < attrs.length; i++) {
        const attrName = attrs[i].name;

        // Check if this is an hx-on attribute
        let eventSpec = null;
        if (attrName.startsWith('hx-on:')) {
          eventSpec = attrName.slice(6); // after 'hx-on:'
        } else if (attrName.startsWith('hx-on-')) {
          eventSpec = attrName.slice(6); // after 'hx-on-'
        } else if (attrName.startsWith('data-hx-on:')) {
          eventSpec = attrName.slice(11); // after 'data-hx-on:'
        } else if (attrName.startsWith('data-hx-on-')) {
          eventSpec = attrName.slice(11); // after 'data-hx-on-'
        }

        if (eventSpec !== null) {
          // Expand :: and -- shorthands to htmx:
          if (eventSpec.startsWith('::')) {
            eventSpec = 'htmx:' + eventSpec.slice(2);
          } else if (eventSpec.startsWith('--')) {
            eventSpec = 'htmx:' + eventSpec.slice(2);
          }

          // Check if this handler matches the current event
          if (eventSpec === eventType) {
            const code = attrs[i].value;

            // Check allowEval configuration
            if (window.htmx && window.htmx.config && window.htmx.config.allowEval === false) {
              const errorEvt = new CustomEvent('htmx:evalDisallowedError', {
                bubbles: true,
                cancelable: true,
                detail: { source: 'hx-on' }
              });
              currentTarget.dispatchEvent(errorEvt);
              return;
            }

            // Get or create handler storage on element
            const key = 'htmx-internal-data';
            let data = currentTarget[key];
            if (!data) {
              data = {};
              currentTarget[key] = data;
            }
            if (!data.hxOnHandlers) {
              data.hxOnHandlers = {};
            }

            // Create or get cached handler
            if (!data.hxOnHandlers[eventType]) {
              try {
                data.hxOnHandlers[eventType] = new Function('event', code);
              } catch (e) {
                console.error('htmx.mbt: Error creating hx-on handler:', e);
                return;
              }
            }

            // Execute handler with element as 'this'
            try {
              data.hxOnHandlers[eventType].call(currentTarget, evt);
            } catch (e) {
              console.error('htmx.mbt: Error executing hx-on handler:', e);
            }

            return;
          }
        }
      }
      currentTarget = currentTarget.parentElement;
    }
  };

  // Register delegation for all common events
  for (const evtType of commonEvents) {
    doc_target.addEventListener(evtType, handleHxOn, { capture: false });
  }
};
const Option$None$4$ = { $tag: 0 };
function Option$Some$4$(param0) {
  this._0 = param0;
}
Option$Some$4$.prototype.$tag = 1;
const $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger = { method_0: moonbitlang$core$builtin$$Logger$write_string$0$, method_1: moonbitlang$core$builtin$$Logger$write_substring$1$, method_2: moonbitlang$core$builtin$$Logger$write_view$0$, method_3: moonbitlang$core$builtin$$Logger$write_char$0$ };
const moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$227 = 0;
const moonbitlang$core$builtin$$brute_force_find$46$constr$47$241 = 0;
const f4ah6o$htmx$src$htmx$$append_query_string$46$42$bind$124$986 = "?";
const f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1048 = "global ";
const f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1049 = "closest ";
const f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1050 = "find ";
const f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1051 = "next";
const f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1055 = "previous";
const f4ah6o$htmx$src$htmx$$resolve_inherit_from_parent$46$42$bind$124$1109 = "inherit";
const f4ah6o$htmx$src$htmx$$values_to_query_string$46$42$bind$124$1233 = "&";
const f4ah6o$htmx$src$htmx$$get_trigger_event$46$42$bind$124$1259 = " ";
const f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$557 = 0;
const f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$558 = 1;
const f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$559 = 2;
const f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$560 = 3;
const f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$561 = 4;
const f4ah6o$htmx$src$htmx$$get_htmx_headers$46$tuple$47$563 = { _0: "HX-Request", _1: "true" };
const f4ah6o$htmx$src$htmx$$get_htmx_headers$46$42$bind$47$564 = [f4ah6o$htmx$src$htmx$$get_htmx_headers$46$tuple$47$563];
const moonbitlang$core$builtin$$seed = moonbitlang$core$builtin$$random_seed();
function moonbitlang$core$abort$$abort$2$(msg) {
  return $panic();
}
function moonbitlang$core$abort$$abort$3$(msg) {
  return $panic();
}
function moonbitlang$core$abort$$abort$4$(msg) {
  $panic();
}
function moonbitlang$core$builtin$$Hasher$consume4(self, input) {
  const _p = (self.acc >>> 0) + ((Math.imul(input, -1028477379) | 0) >>> 0) | 0;
  const _p$2 = 17;
  self.acc = Math.imul(_p << _p$2 | (_p >>> (32 - _p$2 | 0) | 0), 668265263) | 0;
}
function moonbitlang$core$builtin$$Hasher$combine_uint(self, value) {
  self.acc = (self.acc >>> 0) + (4 >>> 0) | 0;
  moonbitlang$core$builtin$$Hasher$consume4(self, value);
}
function moonbitlang$core$builtin$$abort$2$(string, loc) {
  return moonbitlang$core$abort$$abort$2$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$5$(loc)}\n`);
}
function moonbitlang$core$builtin$$abort$3$(string, loc) {
  return moonbitlang$core$abort$$abort$3$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$5$(loc)}\n`);
}
function moonbitlang$core$builtin$$abort$4$(string, loc) {
  moonbitlang$core$abort$$abort$4$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$5$(loc)}\n`);
}
function moonbitlang$core$builtin$$StringBuilder$new$46$inner(size_hint) {
  return { val: "" };
}
function moonbitlang$core$builtin$$Logger$write_char$0$(self, ch) {
  const _bind = self;
  _bind.val = `${_bind.val}${String.fromCodePoint(ch)}`;
}
function moonbitlang$core$builtin$$code_point_of_surrogate_pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function moonbitlang$core$array$$Array$at$6$(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$SourceLocRepr$parse(repr) {
  const _bind = { str: repr, start: 0, end: repr.length };
  const _data = _bind.str;
  const _start = _bind.start;
  const _end = _start + (_bind.end - _bind.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let match_tag_saver_1 = -1;
  let match_tag_saver_2 = -1;
  let match_tag_saver_3 = -1;
  let match_tag_saver_4 = -1;
  let tag_0 = -1;
  let tag_1 = -1;
  let tag_1_1 = -1;
  let tag_1_2 = -1;
  let tag_3 = -1;
  let tag_2 = -1;
  let tag_2_1 = -1;
  let tag_4 = -1;
  _L: {
    let join_dispatch_19;
    _L$2: {
      if (_cursor < _end) {
        const _p = _cursor;
        const next_char = _data.charCodeAt(_p);
        _cursor = _cursor + 1 | 0;
        if (next_char < 65) {
          if (next_char < 64) {
            break _L;
          } else {
            while (true) {
              tag_0 = _cursor;
              if (_cursor < _end) {
                _L$3: {
                  const _p$2 = _cursor;
                  const next_char$2 = _data.charCodeAt(_p$2);
                  _cursor = _cursor + 1 | 0;
                  if (next_char$2 < 55296) {
                    if (next_char$2 < 58) {
                      break _L$3;
                    } else {
                      if (next_char$2 > 58) {
                        break _L$3;
                      } else {
                        if (_cursor < _end) {
                          _L$4: {
                            const _p$3 = _cursor;
                            const next_char$3 = _data.charCodeAt(_p$3);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$3 < 56319) {
                              if (next_char$3 < 55296) {
                                break _L$4;
                              } else {
                                join_dispatch_19 = 7;
                                break _L$2;
                              }
                            } else {
                              if (next_char$3 > 56319) {
                                if (next_char$3 < 65536) {
                                  break _L$4;
                                } else {
                                  break _L;
                                }
                              } else {
                                join_dispatch_19 = 8;
                                break _L$2;
                              }
                            }
                          }
                          join_dispatch_19 = 0;
                          break _L$2;
                        } else {
                          break _L;
                        }
                      }
                    }
                  } else {
                    if (next_char$2 > 56318) {
                      if (next_char$2 < 57344) {
                        if (_cursor < _end) {
                          const _p$3 = _cursor;
                          const next_char$3 = _data.charCodeAt(_p$3);
                          _cursor = _cursor + 1 | 0;
                          if (next_char$3 < 56320) {
                            break _L;
                          } else {
                            if (next_char$3 > 57343) {
                              break _L;
                            } else {
                              continue;
                            }
                          }
                        } else {
                          break _L;
                        }
                      } else {
                        if (next_char$2 > 65535) {
                          break _L;
                        } else {
                          break _L$3;
                        }
                      }
                    } else {
                      if (_cursor < _end) {
                        const _p$3 = _cursor;
                        const next_char$3 = _data.charCodeAt(_p$3);
                        _cursor = _cursor + 1 | 0;
                        if (next_char$3 < 56320) {
                          break _L;
                        } else {
                          if (next_char$3 > 65535) {
                            break _L;
                          } else {
                            continue;
                          }
                        }
                      } else {
                        break _L;
                      }
                    }
                  }
                }
                continue;
              } else {
                break _L;
              }
            }
          }
        } else {
          break _L;
        }
      } else {
        break _L;
      }
    }
    let _tmp = join_dispatch_19;
    _L$3: while (true) {
      const dispatch_19 = _tmp;
      _L$4: {
        _L$5: {
          switch (dispatch_19) {
            case 3: {
              tag_1_2 = tag_1_1;
              tag_1_1 = tag_1;
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        tag_1 = _cursor;
                        tag_2_1 = tag_2;
                        tag_2 = _cursor;
                        tag_3 = _cursor;
                        if (_cursor < _end) {
                          _L$7: {
                            const _p$2 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$2);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 < 59) {
                              if (next_char$2 < 46) {
                                if (next_char$2 < 45) {
                                  break _L$7;
                                } else {
                                  break _L$4;
                                }
                              } else {
                                if (next_char$2 > 47) {
                                  if (next_char$2 < 58) {
                                    _tmp = 6;
                                    continue _L$3;
                                  } else {
                                    _tmp = 3;
                                    continue _L$3;
                                  }
                                } else {
                                  break _L$7;
                                }
                              }
                            } else {
                              if (next_char$2 > 55295) {
                                if (next_char$2 < 57344) {
                                  if (next_char$2 < 56319) {
                                    _tmp = 7;
                                    continue _L$3;
                                  } else {
                                    _tmp = 8;
                                    continue _L$3;
                                  }
                                } else {
                                  if (next_char$2 > 65535) {
                                    break _L;
                                  } else {
                                    break _L$7;
                                  }
                                }
                              } else {
                                break _L$7;
                              }
                            }
                          }
                          _tmp = 0;
                          continue _L$3;
                        } else {
                          break _L;
                        }
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 2: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 2;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 3;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 0: {
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      break _L$6;
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 8: {
              if (_cursor < _end) {
                const _p = _cursor;
                const next_char = _data.charCodeAt(_p);
                _cursor = _cursor + 1 | 0;
                if (next_char < 56320) {
                  break _L;
                } else {
                  if (next_char > 57343) {
                    break _L;
                  } else {
                    _tmp = 0;
                    continue _L$3;
                  }
                }
              } else {
                break _L;
              }
            }
            case 4: {
              tag_1 = _cursor;
              tag_4 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 4;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        tag_1_2 = tag_1_1;
                        tag_1_1 = tag_1;
                        tag_1 = _cursor;
                        if (_cursor < _end) {
                          _L$7: {
                            const _p$2 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$2);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 < 55296) {
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$7;
                                } else {
                                  tag_1 = _cursor;
                                  tag_2_1 = tag_2;
                                  tag_2 = _cursor;
                                  if (_cursor < _end) {
                                    _L$8: {
                                      const _p$3 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$3);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 55296) {
                                        if (next_char$3 < 58) {
                                          if (next_char$3 < 48) {
                                            break _L$8;
                                          } else {
                                            _tmp = 5;
                                            continue _L$3;
                                          }
                                        } else {
                                          if (next_char$3 > 58) {
                                            break _L$8;
                                          } else {
                                            _tmp = 3;
                                            continue _L$3;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 56318) {
                                          if (next_char$3 < 57344) {
                                            _tmp = 8;
                                            continue _L$3;
                                          } else {
                                            if (next_char$3 > 65535) {
                                              break _L;
                                            } else {
                                              break _L$8;
                                            }
                                          }
                                        } else {
                                          _tmp = 7;
                                          continue _L$3;
                                        }
                                      }
                                    }
                                    _tmp = 0;
                                    continue _L$3;
                                  } else {
                                    break _L$5;
                                  }
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$7;
                                } else {
                                  _tmp = 1;
                                  continue _L$3;
                                }
                              }
                            } else {
                              if (next_char$2 > 56318) {
                                if (next_char$2 < 57344) {
                                  _tmp = 8;
                                  continue _L$3;
                                } else {
                                  if (next_char$2 > 65535) {
                                    break _L;
                                  } else {
                                    break _L$7;
                                  }
                                }
                              } else {
                                _tmp = 7;
                                continue _L$3;
                              }
                            }
                          }
                          _tmp = 0;
                          continue _L$3;
                        } else {
                          break _L;
                        }
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 5: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 5;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 3;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L$5;
              }
            }
            case 6: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              tag_3 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 59) {
                    if (next_char < 46) {
                      if (next_char < 45) {
                        break _L$6;
                      } else {
                        break _L$4;
                      }
                    } else {
                      if (next_char > 47) {
                        if (next_char < 58) {
                          _tmp = 6;
                          continue _L$3;
                        } else {
                          _tmp = 3;
                          continue _L$3;
                        }
                      } else {
                        break _L$6;
                      }
                    }
                  } else {
                    if (next_char > 55295) {
                      if (next_char < 57344) {
                        if (next_char < 56319) {
                          _tmp = 7;
                          continue _L$3;
                        } else {
                          _tmp = 8;
                          continue _L$3;
                        }
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      break _L$6;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 7: {
              if (_cursor < _end) {
                const _p = _cursor;
                const next_char = _data.charCodeAt(_p);
                _cursor = _cursor + 1 | 0;
                if (next_char < 56320) {
                  break _L;
                } else {
                  if (next_char > 65535) {
                    break _L;
                  } else {
                    _tmp = 0;
                    continue _L$3;
                  }
                }
              } else {
                break _L;
              }
            }
            case 1: {
              tag_1_1 = tag_1;
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 2;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            default: {
              break _L;
            }
          }
        }
        tag_1 = tag_1_2;
        tag_2 = tag_2_1;
        match_tag_saver_0 = tag_0;
        match_tag_saver_1 = tag_1;
        match_tag_saver_2 = tag_2;
        match_tag_saver_3 = tag_3;
        match_tag_saver_4 = tag_4;
        accept_state = 0;
        match_end = _cursor;
        break _L;
      }
      tag_1_1 = tag_1_2;
      tag_1 = _cursor;
      tag_2 = tag_2_1;
      if (_cursor < _end) {
        _L$5: {
          const _p = _cursor;
          const next_char = _data.charCodeAt(_p);
          _cursor = _cursor + 1 | 0;
          if (next_char < 55296) {
            if (next_char < 58) {
              if (next_char < 48) {
                break _L$5;
              } else {
                _tmp = 4;
                continue;
              }
            } else {
              if (next_char > 58) {
                break _L$5;
              } else {
                _tmp = 1;
                continue;
              }
            }
          } else {
            if (next_char > 56318) {
              if (next_char < 57344) {
                _tmp = 8;
                continue;
              } else {
                if (next_char > 65535) {
                  break _L;
                } else {
                  break _L$5;
                }
              }
            } else {
              _tmp = 7;
              continue;
            }
          }
        }
        _tmp = 0;
        continue;
      } else {
        break _L;
      }
    }
  }
  if (accept_state === 0) {
    let start_line;
    let _try_err;
    _L$2: {
      _L$3: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_1 + 1 | 0, match_tag_saver_2);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          start_line = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err = _tmp;
          break _L$3;
        }
        break _L$2;
      }
      start_line = $panic();
    }
    let start_column;
    let _try_err$2;
    _L$3: {
      _L$4: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_2 + 1 | 0, match_tag_saver_3);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          start_column = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$2 = _tmp;
          break _L$4;
        }
        break _L$3;
      }
      start_column = $panic();
    }
    let pkg;
    let _try_err$3;
    _L$4: {
      _L$5: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, _start + 1 | 0, match_tag_saver_0);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          pkg = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$3 = _tmp;
          break _L$5;
        }
        break _L$4;
      }
      pkg = $panic();
    }
    let filename;
    let _try_err$4;
    _L$5: {
      _L$6: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_0 + 1 | 0, match_tag_saver_1);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          filename = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$4 = _tmp;
          break _L$6;
        }
        break _L$5;
      }
      filename = $panic();
    }
    let end_line;
    let _try_err$5;
    _L$6: {
      _L$7: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_3 + 1 | 0, match_tag_saver_4);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          end_line = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$5 = _tmp;
          break _L$7;
        }
        break _L$6;
      }
      end_line = $panic();
    }
    let end_column;
    let _try_err$6;
    _L$7: {
      _L$8: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_4 + 1 | 0, match_end);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          end_column = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$6 = _tmp;
          break _L$8;
        }
        break _L$7;
      }
      end_column = $panic();
    }
    return { pkg: pkg, filename: filename, start_line: start_line, start_column: start_column, end_line: end_line, end_column: end_column };
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$Logger$write_string$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${str}`;
}
function moonbitlang$core$builtin$$Hasher$combine$7$(self, value) {
  moonbitlang$core$builtin$$Hash$hash_combine$7$(value, self);
}
function moonbitlang$core$builtin$$Hasher$avalanche(self) {
  let acc = self.acc;
  acc = acc ^ (acc >>> 15 | 0);
  acc = Math.imul(acc, -2048144777) | 0;
  acc = acc ^ (acc >>> 13 | 0);
  acc = Math.imul(acc, -1028477379) | 0;
  acc = acc ^ (acc >>> 16 | 0);
  return acc;
}
function moonbitlang$core$builtin$$Hasher$finalize(self) {
  return moonbitlang$core$builtin$$Hasher$avalanche(self);
}
function moonbitlang$core$builtin$$Hasher$new$46$inner(seed) {
  return { acc: (seed >>> 0) + (374761393 >>> 0) | 0 };
}
function moonbitlang$core$builtin$$Hasher$new(seed$46$opt) {
  let seed;
  if (seed$46$opt === undefined) {
    seed = moonbitlang$core$builtin$$seed;
  } else {
    const _Some = seed$46$opt;
    seed = _Some;
  }
  return moonbitlang$core$builtin$$Hasher$new$46$inner(seed);
}
function moonbitlang$core$builtin$$Hash$hash$8$(self) {
  const _self = moonbitlang$core$builtin$$Hasher$new(undefined);
  moonbitlang$core$builtin$$Hasher$combine$7$(_self, self);
  return moonbitlang$core$builtin$$Hasher$finalize(_self);
}
function moonbitlang$core$string$$String$sub$46$inner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    let _tmp;
    if (start$2 < len) {
      const _p = self.charCodeAt(start$2);
      _tmp = 56320 <= _p && _p <= 57343;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    let _tmp$2;
    if (end$2 < len) {
      const _p = self.charCodeAt(end$2);
      _tmp$2 = 56320 <= _p && _p <= 57343;
    } else {
      _tmp$2 = false;
    }
    if (_tmp$2) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    return new Result$Ok$0$({ str: self, start: start$2, end: end$2 });
  } else {
    return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds);
  }
}
function moonbitlang$core$string$$String$sub(self, start$46$opt, end) {
  let start;
  if (start$46$opt === undefined) {
    start = 0;
  } else {
    const _Some = start$46$opt;
    start = _Some;
  }
  return moonbitlang$core$string$$String$sub$46$inner(self, start, end);
}
function moonbitlang$core$builtin$$Logger$write_substring$1$(self, value, start, len) {
  let _tmp;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = moonbitlang$core$string$$String$sub$46$inner(value, start, start + len | 0);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        const _tmp$2 = _err._0;
        _try_err = _tmp$2;
        break _L$2;
      }
      break _L;
    }
    _tmp = $panic();
  }
  moonbitlang$core$builtin$$Logger$write_view$0$(self, _tmp);
}
function moonbitlang$core$builtin$$Show$to_string$5$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$9$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$int$$Int$to_string$46$inner(self, radix) {
  return moonbitlang$core$builtin$$int_to_string_js(self, radix);
}
function moonbitlang$core$builtin$$Show$to_string$3$(self) {
  return self.str.substring(self.start, self.end);
}
function moonbitlang$core$string$$StringView$iter(self) {
  const start = self.start;
  const end = self.end;
  const index = { val: start };
  const _p = () => {
    if (index.val < end) {
      const _tmp = self.str;
      const _tmp$2 = index.val;
      const c1 = _tmp.charCodeAt(_tmp$2);
      if (55296 <= c1 && c1 <= 56319 && (index.val + 1 | 0) < self.end) {
        const _tmp$3 = self.str;
        const _tmp$4 = index.val + 1 | 0;
        const c2 = _tmp$3.charCodeAt(_tmp$4);
        if (56320 <= c2 && c2 <= 57343) {
          index.val = index.val + 2 | 0;
          return moonbitlang$core$builtin$$code_point_of_surrogate_pair(c1, c2);
        }
      }
      index.val = index.val + 1 | 0;
      return c1;
    } else {
      return -1;
    }
  };
  return _p;
}
function moonbitlang$core$builtin$$Iter2$new$10$(f) {
  return f;
}
function moonbitlang$core$string$$StringView$iter2(self) {
  const start = self.start;
  const end = self.end;
  const index = { val: start };
  const char_index = { val: 0 };
  return moonbitlang$core$builtin$$Iter2$new$10$(() => {
    if (index.val < end) {
      const _tmp = self.str;
      const _tmp$2 = index.val;
      const c1 = _tmp.charCodeAt(_tmp$2);
      if (55296 <= c1 && c1 <= 56319 && (index.val + 1 | 0) < self.end) {
        const _tmp$3 = self.str;
        const _tmp$4 = index.val + 1 | 0;
        const c2 = _tmp$3.charCodeAt(_tmp$4);
        if (56320 <= c2 && c2 <= 57343) {
          const result = { _0: char_index.val, _1: moonbitlang$core$builtin$$code_point_of_surrogate_pair(c1, c2) };
          index.val = index.val + 2 | 0;
          char_index.val = char_index.val + 1 | 0;
          return result;
        }
      }
      const result = { _0: char_index.val, _1: c1 };
      index.val = index.val + 1 | 0;
      char_index.val = char_index.val + 1 | 0;
      return result;
    } else {
      return undefined;
    }
  });
}
function moonbitlang$core$string$$String$view$46$inner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= self.length) ? { str: self, start: start_offset, end: end_offset$2 } : moonbitlang$core$builtin$$abort$3$("Invalid index for View", "@moonbitlang/core/builtin:stringview.mbt:382:5-382:36");
}
function moonbitlang$core$string$$String$from_array(chars) {
  const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(Math.imul(chars.end - chars.start | 0, 4) | 0);
  const _len = chars.end - chars.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars.buf[chars.start + _i | 0];
      moonbitlang$core$builtin$$Logger$write_char$0$(buf, c);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return buf.val;
}
function moonbitlang$core$string$$String$char_length_eq$46$inner(self, len, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  let _tmp = start_offset;
  let _tmp$2 = 0;
  while (true) {
    const index = _tmp;
    const count = _tmp$2;
    if (index < end_offset$2 && count < len) {
      const c1 = self.charCodeAt(index);
      if (55296 <= c1 && c1 <= 56319 && (index + 1 | 0) < end_offset$2) {
        const _tmp$3 = index + 1 | 0;
        const c2 = self.charCodeAt(_tmp$3);
        if (56320 <= c2 && c2 <= 57343) {
          _tmp = index + 2 | 0;
          _tmp$2 = count + 1 | 0;
          continue;
        } else {
          moonbitlang$core$builtin$$abort$4$("invalid surrogate pair", "@moonbitlang/core/builtin:string.mbt:426:9-426:40");
        }
      }
      _tmp = index + 1 | 0;
      _tmp$2 = count + 1 | 0;
      continue;
    } else {
      return count === len && index === end_offset$2;
    }
  }
}
function moonbitlang$core$builtin$$Logger$write_view$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${moonbitlang$core$builtin$$Show$to_string$3$(str)}`;
}
function moonbitlang$core$builtin$$boyer_moore_horspool_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      const _end4174 = needle_len - 1 | 0;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _end4174) {
          const _tmp$2 = needle.str;
          const _tmp$3 = needle.start + i | 0;
          const _tmp$4 = _tmp$2.charCodeAt(_tmp$3) & 255;
          $bound_check(skip_table, _tmp$4);
          skip_table[_tmp$4] = (needle_len - 1 | 0) - i | 0;
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$2 = 0;
      while (true) {
        const i = _tmp$2;
        if (i <= (haystack_len - needle_len | 0)) {
          const _end4180 = needle_len - 1 | 0;
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j <= _end4180) {
              const _p = i + j | 0;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p | 0;
              const _tmp$6 = _tmp$4.charCodeAt(_tmp$5);
              const _tmp$7 = needle.str;
              const _tmp$8 = needle.start + j | 0;
              if (_tmp$6 !== _tmp$7.charCodeAt(_tmp$8)) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _p = (i + needle_len | 0) - 1 | 0;
          const _tmp$4 = haystack.str;
          const _tmp$5 = haystack.start + _p | 0;
          const _tmp$6 = _tmp$4.charCodeAt(_tmp$5) & 255;
          $bound_check(skip_table, _tmp$6);
          _tmp$2 = i + skip_table[_tmp$6] | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$227;
  }
}
function moonbitlang$core$builtin$$brute_force_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const _p = 0;
      const _tmp = needle.str;
      const _tmp$2 = needle.start + _p | 0;
      const needle_first = _tmp.charCodeAt(_tmp$2);
      const forward_len = haystack_len - needle_len | 0;
      let i = 0;
      while (true) {
        if (i <= forward_len) {
          while (true) {
            let _tmp$3;
            if (i <= forward_len) {
              const _p$2 = i;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p$2 | 0;
              _tmp$3 = _tmp$4.charCodeAt(_tmp$5) !== needle_first;
            } else {
              _tmp$3 = false;
            }
            if (_tmp$3) {
              i = i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (i <= forward_len) {
            let _tmp$3 = 1;
            while (true) {
              const j = _tmp$3;
              if (j < needle_len) {
                const _p$2 = i + j | 0;
                const _tmp$4 = haystack.str;
                const _tmp$5 = haystack.start + _p$2 | 0;
                const _tmp$6 = _tmp$4.charCodeAt(_tmp$5);
                const _tmp$7 = needle.str;
                const _tmp$8 = needle.start + j | 0;
                if (_tmp$6 !== _tmp$7.charCodeAt(_tmp$8)) {
                  break;
                }
                _tmp$3 = j + 1 | 0;
                continue;
              } else {
                return i;
              }
            }
            i = i + 1 | 0;
          }
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return moonbitlang$core$builtin$$brute_force_find$46$constr$47$241;
  }
}
function moonbitlang$core$string$$StringView$find(self, str) {
  return (str.end - str.start | 0) <= 4 ? moonbitlang$core$builtin$$brute_force_find(self, str) : moonbitlang$core$builtin$$boyer_moore_horspool_find(self, str);
}
function moonbitlang$core$string$$StringView$find_by(self, pred) {
  const _it = moonbitlang$core$string$$StringView$iter2(self);
  while (true) {
    const _bind = moonbitlang$core$builtin$$Iter2$next$10$(_it);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _x = _Some;
      const _i = _x._0;
      const _c = _x._1;
      if (pred(_c)) {
        return _i;
      }
      continue;
    }
  }
  return undefined;
}
function moonbitlang$core$string$$String$find_by(self, pred) {
  return moonbitlang$core$string$$StringView$find_by({ str: self, start: 0, end: self.length }, pred);
}
function moonbitlang$core$string$$StringView$has_prefix(self, str) {
  const _bind = moonbitlang$core$string$$StringView$find(self, str);
  if (_bind === undefined) {
    return false;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i === 0;
  }
}
function moonbitlang$core$string$$String$has_prefix(self, str) {
  return moonbitlang$core$string$$StringView$has_prefix({ str: self, start: 0, end: self.length }, str);
}
function moonbitlang$core$array$$Array$new$46$inner$11$(capacity) {
  return [];
}
function moonbitlang$core$array$$Array$push$12$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$6$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$13$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$7$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$11$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$builtin$$Iter$next$11$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$builtin$$Iter$next$14$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$string$$StringView$contains(self, str) {
  const _bind = moonbitlang$core$string$$StringView$find(self, str);
  return !(_bind === undefined);
}
function moonbitlang$core$string$$String$contains(self, str) {
  return moonbitlang$core$string$$StringView$contains({ str: self, start: 0, end: self.length }, str);
}
function moonbitlang$core$string$$String$iter(self) {
  const len = self.length;
  const index = { val: 0 };
  const _p = () => {
    if (index.val < len) {
      const _tmp = index.val;
      const c1 = self.charCodeAt(_tmp);
      if (55296 <= c1 && c1 <= 56319 && (index.val + 1 | 0) < len) {
        const _tmp$2 = index.val + 1 | 0;
        const c2 = self.charCodeAt(_tmp$2);
        if (56320 <= c2 && c2 <= 57343) {
          const c = moonbitlang$core$builtin$$code_point_of_surrogate_pair(c1, c2);
          index.val = index.val + 2 | 0;
          return c;
        }
      }
      index.val = index.val + 1 | 0;
      return c1;
    } else {
      return -1;
    }
  };
  return _p;
}
function moonbitlang$core$char$$Char$is_ascii_uppercase(self) {
  return self >= 65 && self <= 90;
}
function moonbitlang$core$string$$String$to_lower(self) {
  const _bind = moonbitlang$core$string$$String$find_by(self, (x) => moonbitlang$core$char$$Char$is_ascii_uppercase(x));
  if (_bind === undefined) {
    return self;
  } else {
    const _Some = _bind;
    const _idx = _Some;
    const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(self.length);
    const head = moonbitlang$core$string$$String$view$46$inner(self, 0, _idx);
    moonbitlang$core$builtin$$Logger$write_substring$1$(buf, head.str, head.start, head.end - head.start | 0);
    const _it = moonbitlang$core$string$$StringView$iter(moonbitlang$core$string$$String$view$46$inner(self, _idx, undefined));
    while (true) {
      const _bind$2 = moonbitlang$core$builtin$$Iter$next$11$(_it);
      if (_bind$2 === -1) {
        break;
      } else {
        const _Some$2 = _bind$2;
        const _c = _Some$2;
        if (moonbitlang$core$char$$Char$is_ascii_uppercase(_c)) {
          moonbitlang$core$builtin$$Logger$write_char$0$(buf, _c + 32 | 0);
        } else {
          moonbitlang$core$builtin$$Logger$write_char$0$(buf, _c);
        }
        continue;
      }
    }
    return buf.val;
  }
}
function moonbitlang$core$char$$Char$is_ascii_lowercase(self) {
  return self >= 97 && self <= 122;
}
function moonbitlang$core$string$$String$to_upper(self) {
  const _bind = moonbitlang$core$string$$String$find_by(self, (_hole3904) => moonbitlang$core$char$$Char$is_ascii_lowercase(_hole3904));
  if (_bind === undefined) {
    return self;
  } else {
    const _Some = _bind;
    const _idx = _Some;
    const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(self.length);
    const head = moonbitlang$core$string$$String$view$46$inner(self, 0, _idx);
    moonbitlang$core$builtin$$Logger$write_substring$1$(buf, head.str, head.start, head.end - head.start | 0);
    const _it = moonbitlang$core$string$$StringView$iter(moonbitlang$core$string$$String$view$46$inner(self, _idx, undefined));
    while (true) {
      const _bind$2 = moonbitlang$core$builtin$$Iter$next$11$(_it);
      if (_bind$2 === -1) {
        break;
      } else {
        const _Some$2 = _bind$2;
        const _c = _Some$2;
        if (moonbitlang$core$char$$Char$is_ascii_lowercase(_c)) {
          moonbitlang$core$builtin$$Logger$write_char$0$(buf, _c - 32 | 0);
        } else {
          moonbitlang$core$builtin$$Logger$write_char$0$(buf, _c);
        }
        continue;
      }
    }
    return buf.val;
  }
}
function moonbitlang$core$builtin$$ToStringView$to_string_view$7$(self) {
  return { str: self, start: 0, end: self.length };
}
function moonbitlang$core$string$$String$to_array(self) {
  const _p = moonbitlang$core$string$$String$iter(self);
  const _p$2 = moonbitlang$core$array$$Array$new$46$inner$11$(self.length);
  let _p$3 = _p$2;
  while (true) {
    const _p$4 = moonbitlang$core$builtin$$Iter$next$11$(_p);
    if (_p$4 === -1) {
      break;
    } else {
      const _p$5 = _p$4;
      const _p$6 = _p$5;
      const _p$7 = _p$3;
      moonbitlang$core$array$$Array$push$11$(_p$7, _p$6);
      _p$3 = _p$7;
      continue;
    }
  }
  return _p$3;
}
function moonbitlang$core$int$$Int$next_power_of_two(self) {
  if (self >= 0) {
    if (self <= 1) {
      return 1;
    }
    if (self > 1073741824) {
      return 1073741824;
    }
    return (2147483647 >> (Math.clz32(self - 1 | 0) - 1 | 0)) + 1 | 0;
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$Map$new$46$inner$15$(capacity) {
  const capacity$2 = moonbitlang$core$int$$Int$next_power_of_two(capacity);
  const _bind = capacity$2 - 1 | 0;
  const _bind$2 = (Math.imul(capacity$2, 13) | 0) / 16 | 0;
  const _bind$3 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$4 = undefined;
  return { entries: _bind$3, size: 0, capacity: capacity$2, capacity_mask: _bind, grow_at: _bind$2, head: _bind$4, tail: -1 };
}
function moonbitlang$core$builtin$$Map$add_entry_to_tail$15$(self, idx, entry) {
  const _bind = self.tail;
  if (_bind === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind);
    const _p = _tmp[_bind];
    let _tmp$2;
    if (_p === undefined) {
      _tmp$2 = $panic();
    } else {
      const _p$2 = _p;
      _tmp$2 = _p$2;
    }
    _tmp$2.next = entry;
  }
  self.tail = idx;
  const _tmp = self.entries;
  $bound_check(_tmp, idx);
  _tmp[idx] = entry;
  self.size = self.size + 1 | 0;
}
function moonbitlang$core$builtin$$Map$set_entry$15$(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind = entry.next;
  if (_bind === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function moonbitlang$core$builtin$$Map$push_away$15$(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = idx + 1 & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind = _tmp$4[idx$2];
    if (_bind === undefined) {
      entry$2.psl = psl;
      moonbitlang$core$builtin$$Map$set_entry$15$(self, entry$2, idx$2);
      break;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        moonbitlang$core$builtin$$Map$set_entry$15$(self, entry$2, idx$2);
        _tmp = _curr_entry.psl + 1 | 0;
        _tmp$2 = idx$2 + 1 & self.capacity_mask;
        _tmp$3 = _curr_entry;
        continue;
      } else {
        _tmp = psl + 1 | 0;
        _tmp$2 = idx$2 + 1 & self.capacity_mask;
        continue;
      }
    }
  }
}
function moonbitlang$core$builtin$$Map$set_with_hash$15$(self, key, value, hash) {
  if (self.size >= self.grow_at) {
    moonbitlang$core$builtin$$Map$grow$15$(self);
  }
  let _bind;
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$2 = _tmp$3[idx];
    if (_bind$2 === undefined) {
      _bind = { _0: idx, _1: psl };
      break;
    } else {
      const _Some = _bind$2;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        moonbitlang$core$builtin$$Map$push_away$15$(self, idx, _curr_entry);
        _bind = { _0: idx, _1: psl };
        break;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
  const _idx = _bind._0;
  const _psl = _bind._1;
  const _bind$2 = self.tail;
  const _bind$3 = undefined;
  const entry = { prev: _bind$2, next: _bind$3, psl: _psl, hash: hash, key: key, value: value };
  moonbitlang$core$builtin$$Map$add_entry_to_tail$15$(self, _idx, entry);
}
function moonbitlang$core$builtin$$Map$grow$15$(self) {
  const old_head = self.head;
  const new_capacity = self.capacity << 1;
  self.entries = $make_array_len_and_init(new_capacity, undefined);
  self.capacity = new_capacity;
  self.capacity_mask = new_capacity - 1 | 0;
  const _p = self.capacity;
  self.grow_at = (Math.imul(_p, 13) | 0) / 16 | 0;
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
  let _tmp = old_head;
  while (true) {
    const _param = _tmp;
    if (_param === undefined) {
      return;
    } else {
      const _Some = _param;
      const _x = _Some;
      const _next = _x.next;
      const _key = _x.key;
      const _value = _x.value;
      const _hash = _x.hash;
      moonbitlang$core$builtin$$Map$set_with_hash$15$(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function moonbitlang$core$builtin$$Map$set$15$(self, key, value) {
  moonbitlang$core$builtin$$Map$set_with_hash$15$(self, key, value, moonbitlang$core$builtin$$Hash$hash$8$(key));
}
function moonbitlang$core$builtin$$Map$from_array$15$(arr) {
  const length = arr.end - arr.start | 0;
  let capacity = moonbitlang$core$int$$Int$next_power_of_two(length);
  const _p = capacity;
  if (length > ((Math.imul(_p, 13) | 0) / 16 | 0)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = moonbitlang$core$builtin$$Map$new$46$inner$15$(capacity);
  const _len = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const e = arr.buf[arr.start + _i | 0];
      moonbitlang$core$builtin$$Map$set$15$(m, e._0, e._1);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function moonbitlang$core$builtin$$Iter2$next$10$(self) {
  return moonbitlang$core$builtin$$Iter$next$14$(self);
}
function moonbitlang$core$builtin$$Hasher$combine_string(self, value) {
  const _end2373 = value.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _end2373) {
      moonbitlang$core$builtin$$Hasher$combine_uint(self, value.charCodeAt(i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function moonbitlang$core$builtin$$Hash$hash_combine$7$(self, hasher) {
  moonbitlang$core$builtin$$Hasher$combine_string(hasher, self);
}
function moonbitlang$core$builtin$$Show$output$16$(self, logger) {
  const pkg = self.pkg;
  const _data = pkg.str;
  const _start = pkg.start;
  const _end = _start + (pkg.end - pkg.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let tag_0 = -1;
  let _bind;
  _L: {
    _L$2: {
      _L$3: while (true) {
        if (_cursor < _end) {
          _L$4: {
            _L$5: {
              const _p = _cursor;
              const next_char = _data.charCodeAt(_p);
              _cursor = _cursor + 1 | 0;
              if (next_char < 55296) {
                if (next_char < 47) {
                  break _L$5;
                } else {
                  if (next_char > 47) {
                    break _L$5;
                  } else {
                    _L$6: while (true) {
                      tag_0 = _cursor;
                      if (_cursor < _end) {
                        _L$7: {
                          const _p$2 = _cursor;
                          const next_char$2 = _data.charCodeAt(_p$2);
                          _cursor = _cursor + 1 | 0;
                          if (next_char$2 < 55296) {
                            if (next_char$2 < 47) {
                              break _L$7;
                            } else {
                              if (next_char$2 > 47) {
                                break _L$7;
                              } else {
                                while (true) {
                                  if (_cursor < _end) {
                                    _L$8: {
                                      const _p$3 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$3);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 56319) {
                                        if (next_char$3 < 55296) {
                                          break _L$8;
                                        } else {
                                          if (_cursor < _end) {
                                            const _p$4 = _cursor;
                                            const next_char$4 = _data.charCodeAt(_p$4);
                                            _cursor = _cursor + 1 | 0;
                                            if (next_char$4 < 56320) {
                                              break _L$2;
                                            } else {
                                              if (next_char$4 > 65535) {
                                                break _L$2;
                                              } else {
                                                continue;
                                              }
                                            }
                                          } else {
                                            break _L$2;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 56319) {
                                          if (next_char$3 < 65536) {
                                            break _L$8;
                                          } else {
                                            break _L$2;
                                          }
                                        } else {
                                          if (_cursor < _end) {
                                            const _p$4 = _cursor;
                                            const next_char$4 = _data.charCodeAt(_p$4);
                                            _cursor = _cursor + 1 | 0;
                                            if (next_char$4 < 56320) {
                                              break _L$2;
                                            } else {
                                              if (next_char$4 > 57343) {
                                                break _L$2;
                                              } else {
                                                continue;
                                              }
                                            }
                                          } else {
                                            break _L$2;
                                          }
                                        }
                                      }
                                    }
                                    continue;
                                  } else {
                                    match_tag_saver_0 = tag_0;
                                    accept_state = 0;
                                    match_end = _cursor;
                                    break _L$2;
                                  }
                                }
                              }
                            }
                          } else {
                            if (next_char$2 > 56318) {
                              if (next_char$2 < 57344) {
                                if (_cursor < _end) {
                                  const _p$3 = _cursor;
                                  const next_char$3 = _data.charCodeAt(_p$3);
                                  _cursor = _cursor + 1 | 0;
                                  if (next_char$3 < 56320) {
                                    break _L$2;
                                  } else {
                                    if (next_char$3 > 57343) {
                                      break _L$2;
                                    } else {
                                      continue;
                                    }
                                  }
                                } else {
                                  break _L$2;
                                }
                              } else {
                                if (next_char$2 > 65535) {
                                  break _L$2;
                                } else {
                                  break _L$7;
                                }
                              }
                            } else {
                              if (_cursor < _end) {
                                const _p$3 = _cursor;
                                const next_char$3 = _data.charCodeAt(_p$3);
                                _cursor = _cursor + 1 | 0;
                                if (next_char$3 < 56320) {
                                  break _L$2;
                                } else {
                                  if (next_char$3 > 65535) {
                                    break _L$2;
                                  } else {
                                    continue;
                                  }
                                }
                              } else {
                                break _L$2;
                              }
                            }
                          }
                        }
                        continue;
                      } else {
                        break _L$2;
                      }
                    }
                  }
                }
              } else {
                if (next_char > 56318) {
                  if (next_char < 57344) {
                    if (_cursor < _end) {
                      const _p$2 = _cursor;
                      const next_char$2 = _data.charCodeAt(_p$2);
                      _cursor = _cursor + 1 | 0;
                      if (next_char$2 < 56320) {
                        break _L$2;
                      } else {
                        if (next_char$2 > 57343) {
                          break _L$2;
                        } else {
                          continue;
                        }
                      }
                    } else {
                      break _L$2;
                    }
                  } else {
                    if (next_char > 65535) {
                      break _L$2;
                    } else {
                      break _L$5;
                    }
                  }
                } else {
                  if (_cursor < _end) {
                    const _p$2 = _cursor;
                    const next_char$2 = _data.charCodeAt(_p$2);
                    _cursor = _cursor + 1 | 0;
                    if (next_char$2 < 56320) {
                      break _L$2;
                    } else {
                      if (next_char$2 > 65535) {
                        break _L$2;
                      } else {
                        continue;
                      }
                    }
                  } else {
                    break _L$2;
                  }
                }
              }
              break _L$4;
            }
            continue;
          }
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    if (accept_state === 0) {
      let package_name;
      let _try_err;
      _L$3: {
        _L$4: {
          const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_0 + 1 | 0, match_end);
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            package_name = _ok._0;
          } else {
            const _err = _bind$2;
            const _tmp = _err._0;
            _try_err = _tmp;
            break _L$4;
          }
          break _L$3;
        }
        package_name = $panic();
      }
      let module_name;
      let _try_err$2;
      _L$4: {
        _L$5: {
          const _bind$2 = moonbitlang$core$string$$String$sub(_data, _start, match_tag_saver_0);
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            module_name = _ok._0;
          } else {
            const _err = _bind$2;
            const _tmp = _err._0;
            _try_err$2 = _tmp;
            break _L$5;
          }
          break _L$4;
        }
        module_name = $panic();
      }
      _bind = { _0: module_name, _1: package_name };
    } else {
      _bind = { _0: pkg, _1: undefined };
    }
  }
  const _module_name = _bind._0;
  const _package_name = _bind._1;
  if (_package_name === undefined) {
  } else {
    const _Some = _package_name;
    const _pkg_name = _Some;
    logger.method_table.method_2(logger.self, _pkg_name);
    logger.method_table.method_3(logger.self, 47);
  }
  logger.method_table.method_2(logger.self, self.filename);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_column);
  logger.method_table.method_3(logger.self, 45);
  logger.method_table.method_2(logger.self, self.end_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.end_column);
  logger.method_table.method_3(logger.self, 64);
  logger.method_table.method_2(logger.self, _module_name);
}
function moonbitlang$core$builtin$$Show$output$9$(self, logger) {
  moonbitlang$core$builtin$$Show$output$16$(moonbitlang$core$builtin$$SourceLocRepr$parse(self), logger);
}
function moonbitlang$core$array$$Array$sub$46$inner$11$(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  return start$2 >= 0 && (start$2 <= end$2 && end$2 <= len) ? { buf: self, start: start$2, end: end$2 } : moonbitlang$core$builtin$$abort$2$("View index out of bounds", "@moonbitlang/core/builtin:arrayview.mbt:251:5-251:38");
}
function moonbitlang$core$array$$ArrayView$join$7$(self, separator) {
  if ((self.end - self.start | 0) === 0) {
    return "";
  } else {
    const _hd = self.buf[self.start];
    const _bind = self.buf;
    const _bind$2 = 1 + self.start | 0;
    const _bind$3 = self.end;
    const _x = { buf: _bind, start: _bind$2, end: _bind$3 };
    const hd = moonbitlang$core$builtin$$ToStringView$to_string_view$7$(_hd);
    let size_hint = hd.end - hd.start | 0;
    const _len = _x.end - _x.start | 0;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const s = _bind[_bind$2 + _i | 0];
        const _tmp$2 = size_hint;
        const _p = moonbitlang$core$builtin$$ToStringView$to_string_view$7$(s);
        size_hint = _tmp$2 + ((_p.end - _p.start | 0) + (separator.end - separator.start | 0) | 0) | 0;
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    size_hint = size_hint << 1;
    const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(size_hint);
    moonbitlang$core$builtin$$Logger$write_view$0$(buf, hd);
    if (moonbitlang$core$string$$String$char_length_eq$46$inner(separator.str, 0, separator.start, separator.end)) {
      const _len$2 = _x.end - _x.start | 0;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const s = _bind[_bind$2 + _i | 0];
          const s$2 = moonbitlang$core$builtin$$ToStringView$to_string_view$7$(s);
          moonbitlang$core$builtin$$Logger$write_view$0$(buf, s$2);
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    } else {
      const _len$2 = _x.end - _x.start | 0;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const s = _bind[_bind$2 + _i | 0];
          const s$2 = moonbitlang$core$builtin$$ToStringView$to_string_view$7$(s);
          moonbitlang$core$builtin$$Logger$write_view$0$(buf, separator);
          moonbitlang$core$builtin$$Logger$write_view$0$(buf, s$2);
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
    return buf.val;
  }
}
function moonbitlang$core$array$$Array$join$7$(self, separator) {
  return moonbitlang$core$array$$ArrayView$join$7$({ buf: self, start: 0, end: self.length }, separator);
}
function mizchi$js$core$$identity_option$7$(v) {
  return mizchi$js$core$$is_nullish(v) ? undefined : v;
}
function mizchi$js$core$$identity_option$6$(v) {
  return mizchi$js$core$$is_nullish(v) ? Option$None$1$ : new Option$Some$1$(v);
}
function mizchi$js$web$event$$EventTarget$addEventListener$46$inner(self, event_type, handler, capture, once, passive, signal) {
  const entries = [];
  moonbitlang$core$array$$Array$push$12$(entries, { _0: "capture", _1: capture });
  moonbitlang$core$array$$Array$push$12$(entries, { _0: "once", _1: once });
  moonbitlang$core$array$$Array$push$12$(entries, { _0: "passive", _1: passive });
  if (signal.$tag === 1) {
    const _Some = signal;
    const _v = _Some._0;
    moonbitlang$core$array$$Array$push$12$(entries, { _0: "signal", _1: _v });
  }
  mizchi$js$core$$Any$_call(self, "addEventListener", [event_type, handler, mizchi$js$core$$from_entries(entries)]);
}
function mizchi$js$browser$dom$$Element$getAttribute(self, name) {
  const v = mizchi$js$core$$Any$_call(self, "getAttribute", [name]);
  return mizchi$js$core$$identity_option$7$(v);
}
function mizchi$js$browser$dom$$Element$hasAttribute(self, name) {
  return mizchi$js$core$$Any$_call(self, "hasAttribute", [name]);
}
function mizchi$js$browser$dom$$Element$querySelector(self, selector) {
  const v = mizchi$js$core$$Any$_call(self, "querySelector", [selector]);
  return mizchi$js$core$$identity_option$6$(v);
}
function mizchi$js$browser$dom$$Element$querySelectorAll(self, selector) {
  const arr = mizchi$js$core$$Any$_call(self, "querySelectorAll", [selector]);
  const _p = mizchi$js$core$$array_from(arr);
  const _p$2 = new Array(_p.length);
  const _p$3 = _p.length;
  let _tmp = 0;
  while (true) {
    const _p$4 = _tmp;
    if (_p$4 < _p$3) {
      const _p$5 = _p[_p$4];
      _p$2[_p$4] = _p$5;
      _tmp = _p$4 + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return _p$2;
}
function mizchi$js$browser$dom$$Element$closest(self, selector) {
  const v = mizchi$js$core$$Any$_call(self, "closest", [selector]);
  return mizchi$js$core$$identity_option$6$(v);
}
function mizchi$js$browser$dom$$Document$querySelector(self, selector) {
  const v = mizchi$js$core$$Any$_call(self, "querySelector", [selector]);
  return mizchi$js$core$$identity_option$6$(v);
}
function f4ah6o$htmx$src$htmx$$get_expression_vars(elt, event) {
  return f4ah6o$htmx$src$htmx$$get_expression_vars_inner(elt, event);
}
function f4ah6o$htmx$src$htmx$$validate_element(element) {
  const tag = moonbitlang$core$string$$String$to_lower(mizchi$js$browser$dom$$Element$tagName(element));
  let _tmp;
  const _p = "form";
  if (!(tag === _p)) {
    _tmp = f4ah6o$htmx$src$htmx$$has_hx_validate(element);
  } else {
    _tmp = false;
  }
  if (_tmp) {
    f4ah6o$htmx$src$htmx$$dispatch_validate_event(element);
    if (!f4ah6o$htmx$src$htmx$$element_check_validity(element)) {
      const detail = mizchi$js$core$$new_object();
      mizchi$js$core$$Any$_set(detail, "elt", element);
      mizchi$js$core$$Any$_set(detail, "message", mizchi$js$core$$new_object());
      f4ah6o$htmx$src$htmx$$dispatch_validation_failed_event(element, detail);
      return false;
    }
    return true;
  }
  if (tag === "form") {
    if (f4ah6o$htmx$src$htmx$$has_novalidate(element)) {
      return true;
    }
    f4ah6o$htmx$src$htmx$$dispatch_validate_events(element);
    const invalids = f4ah6o$htmx$src$htmx$$get_invalid_elements(element);
    if (invalids.length > 0) {
      const errors = f4ah6o$htmx$src$htmx$$create_errors_array(invalids);
      f4ah6o$htmx$src$htmx$$dispatch_validation_halted(element, errors);
      if (f4ah6o$htmx$src$htmx$$get_config_report_validity()) {
        const first = moonbitlang$core$array$$Array$at$6$(invalids, 0);
        f4ah6o$htmx$src$htmx$$focus_element(first);
        f4ah6o$htmx$src$htmx$$form_report_validity(element);
      }
      return false;
    }
  }
  return true;
}
function f4ah6o$htmx$src$htmx$$validate_element_with_trigger(element, trigger_el) {
  if (trigger_el.$tag === 1) {
    const _Some = trigger_el;
    const _trig = _Some._0;
    if (f4ah6o$htmx$src$htmx$$has_formnovalidate(_trig)) {
      return true;
    }
  }
  return f4ah6o$htmx$src$htmx$$validate_element(element);
}
function f4ah6o$htmx$src$htmx$$SwapStyle$parse(value) {
  switch (value) {
    case "innerHTML": {
      return 0;
    }
    case "outerHTML": {
      return 1;
    }
    case "beforebegin": {
      return 2;
    }
    case "afterbegin": {
      return 3;
    }
    case "beforeend": {
      return 4;
    }
    case "afterend": {
      return 5;
    }
    case "delete": {
      return 6;
    }
    case "none": {
      return 8;
    }
    case "morph": {
      return 7;
    }
    default: {
      return 0;
    }
  }
}
function f4ah6o$htmx$src$htmx$$SwapStyle$to_htmx_string(self) {
  switch (self) {
    case 0: {
      return "innerHTML";
    }
    case 1: {
      return "outerHTML";
    }
    case 2: {
      return "beforebegin";
    }
    case 3: {
      return "afterbegin";
    }
    case 4: {
      return "beforeend";
    }
    case 5: {
      return "afterend";
    }
    case 6: {
      return "delete";
    }
    case 8: {
      return "none";
    }
    default: {
      return "morph";
    }
  }
}
function f4ah6o$htmx$src$htmx$$HttpMethod$to_string(self) {
  switch (self) {
    case 0: {
      return "GET";
    }
    case 1: {
      return "POST";
    }
    case 2: {
      return "PUT";
    }
    case 3: {
      return "DELETE";
    }
    default: {
      return "PATCH";
    }
  }
}
function f4ah6o$htmx$src$htmx$$HttpMethod$has_body(self) {
  switch (self) {
    case 1: {
      return true;
    }
    case 2: {
      return true;
    }
    case 4: {
      return true;
    }
    case 0: {
      return false;
    }
    default: {
      return false;
    }
  }
}
function f4ah6o$htmx$src$htmx$$HttpMethod$from_attr(attr) {
  switch (attr) {
    case "hx-get": {
      return f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$557;
    }
    case "hx-post": {
      return f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$558;
    }
    case "hx-put": {
      return f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$559;
    }
    case "hx-delete": {
      return f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$560;
    }
    case "hx-patch": {
      return f4ah6o$htmx$src$htmx$$from_attr$46$constr$47$561;
    }
    default: {
      return undefined;
    }
  }
}
function f4ah6o$htmx$src$htmx$$get_htmx_headers(trigger_element) {
  const headers = moonbitlang$core$builtin$$Map$from_array$15$({ buf: f4ah6o$htmx$src$htmx$$get_htmx_headers$46$42$bind$47$564, start: 0, end: 1 });
  if (trigger_element.$tag === 1) {
    const _Some = trigger_element;
    const _el = _Some._0;
    const _bind = mizchi$js$browser$dom$$Element$getAttribute(_el, "id");
    if (_bind === undefined) {
    } else {
      const _Some$2 = _bind;
      const _id = _Some$2;
      moonbitlang$core$builtin$$Map$set$15$(headers, "HX-Trigger", _id);
    }
    const _bind$2 = mizchi$js$browser$dom$$Element$getAttribute(_el, "name");
    if (_bind$2 === undefined) {
    } else {
      const _Some$2 = _bind$2;
      const _name = _Some$2;
      moonbitlang$core$builtin$$Map$set$15$(headers, "HX-Trigger-Name", _name);
    }
  }
  return headers;
}
function f4ah6o$htmx$src$htmx$$request_async(url, http_method, trigger_element, callback) {
  const headers = f4ah6o$htmx$src$htmx$$get_htmx_headers(trigger_element);
  const headers_obj = f4ah6o$htmx$src$htmx$$map_to_js_object(headers);
  f4ah6o$htmx$src$htmx$$request_async_callback(url, f4ah6o$htmx$src$htmx$$HttpMethod$to_string(http_method), trigger_element, headers_obj, callback);
}
function f4ah6o$htmx$src$htmx$$request_with_form_async(url, http_method, form_data, trigger_element, callback) {
  const headers = f4ah6o$htmx$src$htmx$$get_htmx_headers(trigger_element);
  const headers_obj = f4ah6o$htmx$src$htmx$$map_to_js_object(headers);
  if (form_data.$tag === 1) {
    const _Some = form_data;
    const _fd = _Some._0;
    f4ah6o$htmx$src$htmx$$request_with_form_async_callback(url, f4ah6o$htmx$src$htmx$$HttpMethod$to_string(http_method), _fd, trigger_element, headers_obj, callback);
    return;
  } else {
    f4ah6o$htmx$src$htmx$$request_async_callback(url, f4ah6o$htmx$src$htmx$$HttpMethod$to_string(http_method), trigger_element, headers_obj, callback);
    return;
  }
}
function f4ah6o$htmx$src$htmx$$append_query_string(url, query) {
  if (query.length === 0) {
    return url;
  }
  return moonbitlang$core$string$$String$contains(url, { str: f4ah6o$htmx$src$htmx$$append_query_string$46$42$bind$124$986, start: 0, end: f4ah6o$htmx$src$htmx$$append_query_string$46$42$bind$124$986.length }) ? `${url}&${query}` : `${url}?${query}`;
}
function f4ah6o$htmx$src$htmx$$get_input_value(element) {
  const tag = moonbitlang$core$string$$String$to_upper(mizchi$js$browser$dom$$Element$tagName(element));
  _L: {
    switch (tag) {
      case "INPUT": {
        const _p = mizchi$js$browser$dom$$Element$getAttribute(element, "type");
        const _p$2 = "text";
        let _tmp;
        if (_p === undefined) {
          _tmp = _p$2;
        } else {
          const _p$3 = _p;
          _tmp = _p$3;
        }
        const input_type = moonbitlang$core$string$$String$to_lower(_tmp);
        _L$2: {
          switch (input_type) {
            case "checkbox": {
              break _L$2;
            }
            case "radio": {
              break _L$2;
            }
            case "file": {
              return undefined;
            }
            default: {
              return f4ah6o$htmx$src$htmx$$get_element_value(element);
            }
          }
        }
        if (mizchi$js$browser$dom$$Element$hasAttribute(element, "checked")) {
          const _p$3 = mizchi$js$browser$dom$$Element$getAttribute(element, "value");
          const _p$4 = "on";
          if (_p$3 === undefined) {
            return _p$4;
          } else {
            const _p$5 = _p$3;
            return _p$5;
          }
        } else {
          const checked = f4ah6o$htmx$src$htmx$$get_element_checked(element);
          if (checked) {
            const _p$3 = mizchi$js$browser$dom$$Element$getAttribute(element, "value");
            const _p$4 = "on";
            if (_p$3 === undefined) {
              return _p$4;
            } else {
              const _p$5 = _p$3;
              return _p$5;
            }
          } else {
            return undefined;
          }
        }
      }
      case "SELECT": {
        break _L;
      }
      case "TEXTAREA": {
        break _L;
      }
      default: {
        return undefined;
      }
    }
  }
  return f4ah6o$htmx$src$htmx$$get_element_value(element);
}
function f4ah6o$htmx$src$htmx$$collect_input_values(form) {
  const result = [];
  const inputs = mizchi$js$browser$dom$$Element$querySelectorAll(form, "input, select, textarea");
  const _len = inputs.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const element = inputs[_i];
      const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, "name");
      if (_bind === undefined) {
      } else {
        const _Some = _bind;
        const _name = _Some;
        if (_name.length > 0) {
          const value = f4ah6o$htmx$src$htmx$$get_input_value(element);
          if (value === undefined) {
          } else {
            const _Some$2 = value;
            const _v = _Some$2;
            moonbitlang$core$array$$Array$push$13$(result, { _0: _name, _1: _v });
          }
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function f4ah6o$htmx$src$htmx$$disable_elements(elements) {
  const _len = elements.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const el = elements[_i];
      f4ah6o$htmx$src$htmx$$inc_request_count(el);
      f4ah6o$htmx$src$htmx$$set_disabled_attr(el);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function f4ah6o$htmx$src$htmx$$find_method_url(element) {
  const methods = ["hx-get", "hx-post", "hx-put", "hx-delete", "hx-patch"];
  const _len = methods.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      _L: {
        const method_attr = methods[_i];
        if (mizchi$js$browser$dom$$Element$hasAttribute(element, method_attr)) {
          const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, method_attr);
          if (_bind === undefined) {
            break _L;
          } else {
            const _Some = _bind;
            const _url = _Some;
            const _bind$2 = f4ah6o$htmx$src$htmx$$HttpMethod$from_attr(method_attr);
            if (_bind$2 === undefined) {
              break _L;
            } else {
              const _Some$2 = _bind$2;
              const _m = _Some$2;
              return { _0: _m, _1: _url };
            }
          }
        }
        const data_attr = `data-${method_attr}`;
        if (mizchi$js$browser$dom$$Element$hasAttribute(element, data_attr)) {
          const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, data_attr);
          if (_bind === undefined) {
            break _L;
          } else {
            const _Some = _bind;
            const _url = _Some;
            const _bind$2 = f4ah6o$htmx$src$htmx$$HttpMethod$from_attr(method_attr);
            if (_bind$2 === undefined) {
              break _L;
            } else {
              const _Some$2 = _bind$2;
              const _m = _Some$2;
              return { _0: _m, _1: _url };
            }
          }
        }
        break _L;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return undefined;
}
function f4ah6o$htmx$src$htmx$$find_next_matching_opt(element, selector) {
  let _tmp = element;
  while (true) {
    const element$2 = _tmp;
    const _bind = f4ah6o$htmx$src$htmx$$get_next_sibling(element$2);
    if (_bind.$tag === 1) {
      const _Some = _bind;
      const _next = _Some._0;
      if (selector === "" || f4ah6o$htmx$src$htmx$$element_matches(_next, selector)) {
        return new Option$Some$1$(_next);
      } else {
        _tmp = _next;
        continue;
      }
    } else {
      return Option$None$1$;
    }
  }
}
function f4ah6o$htmx$src$htmx$$find_next_sibling_opt(element, selector) {
  const _bind = f4ah6o$htmx$src$htmx$$get_next_sibling(element);
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _next = _Some._0;
    return selector === "" || f4ah6o$htmx$src$htmx$$element_matches(_next, selector) ? new Option$Some$1$(_next) : f4ah6o$htmx$src$htmx$$find_next_matching_opt(_next, selector);
  } else {
    return Option$None$1$;
  }
}
function f4ah6o$htmx$src$htmx$$find_previous_matching_opt(element, selector) {
  let _tmp = element;
  while (true) {
    const element$2 = _tmp;
    const _bind = f4ah6o$htmx$src$htmx$$get_previous_sibling(element$2);
    if (_bind.$tag === 1) {
      const _Some = _bind;
      const _prev = _Some._0;
      if (selector === "" || f4ah6o$htmx$src$htmx$$element_matches(_prev, selector)) {
        return new Option$Some$1$(_prev);
      } else {
        _tmp = _prev;
        continue;
      }
    } else {
      return Option$None$1$;
    }
  }
}
function f4ah6o$htmx$src$htmx$$find_previous_sibling_opt(element, selector) {
  const _bind = f4ah6o$htmx$src$htmx$$get_previous_sibling(element);
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _prev = _Some._0;
    return selector === "" || f4ah6o$htmx$src$htmx$$element_matches(_prev, selector) ? new Option$Some$1$(_prev) : f4ah6o$htmx$src$htmx$$find_previous_matching_opt(_prev, selector);
  } else {
    return Option$None$1$;
  }
}
function f4ah6o$htmx$src$htmx$$parse_extended_target(element, selector) {
  f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: selector = '${selector}'`);
  if (selector === "this") {
    f4ah6o$htmx$src$htmx$$log_debug_attr("parse_extended_target: this -> returning element");
    return new Option$Some$1$(element);
  } else {
    if (moonbitlang$core$string$$String$has_prefix(selector, { str: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1048, start: 0, end: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1048.length })) {
      const css = f4ah6o$htmx$src$htmx$$substring_after(selector, 7);
      f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: global '${css}'`);
      return mizchi$js$browser$dom$$Document$querySelector(mizchi$js$browser$dom$$document(), css);
    } else {
      if (moonbitlang$core$string$$String$has_prefix(selector, { str: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1049, start: 0, end: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1049.length })) {
        const css = f4ah6o$htmx$src$htmx$$substring_after(selector, 8);
        f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: closest '${css}'`);
        return mizchi$js$browser$dom$$Element$closest(element, css);
      } else {
        if (moonbitlang$core$string$$String$has_prefix(selector, { str: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1050, start: 0, end: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1050.length })) {
          const css = f4ah6o$htmx$src$htmx$$substring_after(selector, 5);
          f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: find '${css}'`);
          return mizchi$js$browser$dom$$Element$querySelector(element, css);
        } else {
          if (moonbitlang$core$string$$String$has_prefix(selector, { str: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1051, start: 0, end: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1051.length })) {
            const rest = f4ah6o$htmx$src$htmx$$trim_string(f4ah6o$htmx$src$htmx$$substring_after(selector, 4));
            f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: next with rest = '${rest}'`);
            const result = f4ah6o$htmx$src$htmx$$find_next_sibling_opt(element, rest);
            if (result.$tag === 1) {
              f4ah6o$htmx$src$htmx$$log_debug_attr("parse_extended_target: next found element");
            } else {
              f4ah6o$htmx$src$htmx$$log_debug_attr("parse_extended_target: next NOT found");
            }
            return result;
          } else {
            if (moonbitlang$core$string$$String$has_prefix(selector, { str: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1055, start: 0, end: f4ah6o$htmx$src$htmx$$parse_extended_target$46$42$bind$124$1055.length })) {
              const rest = f4ah6o$htmx$src$htmx$$trim_string(f4ah6o$htmx$src$htmx$$substring_after(selector, 8));
              f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: previous with rest = '${rest}'`);
              return f4ah6o$htmx$src$htmx$$find_previous_sibling_opt(element, rest);
            } else {
              f4ah6o$htmx$src$htmx$$log_debug_attr(`parse_extended_target: default selector '${selector}'`);
              return mizchi$js$browser$dom$$Document$querySelector(mizchi$js$browser$dom$$document(), selector);
            }
          }
        }
      }
    }
  }
}
function f4ah6o$htmx$src$htmx$$find_targets_by_selector(element, selector) {
  const parts = f4ah6o$htmx$src$htmx$$split_by_comma(selector);
  const results = [];
  const _len = parts.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const part = parts[_i];
      const _p = "";
      if (!(part === _p)) {
        const _bind = f4ah6o$htmx$src$htmx$$parse_extended_target(element, part);
        if (_bind.$tag === 1) {
          const _Some = _bind;
          const _target = _Some._0;
          moonbitlang$core$array$$Array$push$6$(results, _target);
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return results;
}
function f4ah6o$htmx$src$htmx$$get_disabled_elt(element) {
  const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, "hx-disabled-elt");
  if (_bind === undefined) {
    const _bind$2 = mizchi$js$browser$dom$$Element$getAttribute(element, "data-hx-disabled-elt");
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      return _value;
    }
  } else {
    const _Some = _bind;
    const _value = _Some;
    return _value;
  }
}
function f4ah6o$htmx$src$htmx$$get_form_data(element) {
  const tag = moonbitlang$core$string$$String$to_upper(mizchi$js$browser$dom$$Element$tagName(element));
  if (tag === "FORM") {
    return new Option$Some$2$(f4ah6o$htmx$src$htmx$$form_data_from_element(element));
  }
  const _bind = mizchi$js$browser$dom$$Element$closest(element, "form");
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _form = _Some._0;
    return new Option$Some$2$(f4ah6o$htmx$src$htmx$$form_data_from_element(_form));
  } else {
    return Option$None$2$;
  }
}
function f4ah6o$htmx$src$htmx$$get_indicator(element) {
  const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, "hx-indicator");
  if (_bind === undefined) {
    const _bind$2 = mizchi$js$browser$dom$$Element$getAttribute(element, "data-hx-indicator");
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      return _value;
    }
  } else {
    const _Some = _bind;
    const _value = _Some;
    return _value;
  }
}
function f4ah6o$htmx$src$htmx$$find_indicator_owner(element) {
  const _bind = f4ah6o$htmx$src$htmx$$get_indicator(element);
  if (_bind === undefined) {
    const _bind$2 = mizchi$js$browser$dom$$Element$closest(element, "[hx-indicator], [data-hx-indicator]");
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _owner = _Some._0;
      const _bind$3 = f4ah6o$htmx$src$htmx$$get_indicator(_owner);
      if (_bind$3 === undefined) {
        return undefined;
      } else {
        const _Some$2 = _bind$3;
        const _selector = _Some$2;
        return { _0: _owner, _1: _selector };
      }
    } else {
      return undefined;
    }
  } else {
    const _Some = _bind;
    const _selector = _Some;
    return { _0: element, _1: _selector };
  }
}
function f4ah6o$htmx$src$htmx$$combine_selectors(base, with_inherit) {
  const parts = f4ah6o$htmx$src$htmx$$split_by_comma(with_inherit);
  const results = [];
  const _len = parts.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const part = parts[_i];
      if (part === "inherit") {
        const base_parts = f4ah6o$htmx$src$htmx$$split_by_comma(base);
        const _len$2 = base_parts.length;
        let _tmp$2 = 0;
        while (true) {
          const _i$2 = _tmp$2;
          if (_i$2 < _len$2) {
            const bp = base_parts[_i$2];
            const _p = "";
            if (!(bp === _p)) {
              moonbitlang$core$array$$Array$push$7$(results, bp);
            }
            _tmp$2 = _i$2 + 1 | 0;
            continue;
          } else {
            break;
          }
        }
      } else {
        const _p = "";
        if (!(part === _p)) {
          moonbitlang$core$array$$Array$push$7$(results, part);
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return f4ah6o$htmx$src$htmx$$join_with_comma(results);
}
function f4ah6o$htmx$src$htmx$$extract_non_inherit(selector) {
  const parts = f4ah6o$htmx$src$htmx$$split_by_comma(selector);
  const results = [];
  const _len = parts.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const part = parts[_i];
      let _tmp$2;
      const _p = "inherit";
      if (!(part === _p)) {
        const _p$2 = "";
        _tmp$2 = !(part === _p$2);
      } else {
        _tmp$2 = false;
      }
      if (_tmp$2) {
        moonbitlang$core$array$$Array$push$7$(results, part);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return f4ah6o$htmx$src$htmx$$join_with_comma(results);
}
function f4ah6o$htmx$src$htmx$$resolve_inherit_from_parent(element) {
  let _tmp = element;
  while (true) {
    const element$2 = _tmp;
    const _bind = f4ah6o$htmx$src$htmx$$get_parent_element(element$2);
    if (_bind.$tag === 1) {
      const _Some = _bind;
      const _parent = _Some._0;
      f4ah6o$htmx$src$htmx$$log_debug_attr("resolve_inherit_from_parent: found parent");
      const _bind$2 = mizchi$js$browser$dom$$Element$closest(_parent, "[hx-indicator], [data-hx-indicator]");
      if (_bind$2.$tag === 1) {
        const _Some$2 = _bind$2;
        const _indicator_owner = _Some$2._0;
        f4ah6o$htmx$src$htmx$$log_debug_attr("resolve_inherit_from_parent: closest found indicator_owner");
        const _bind$3 = f4ah6o$htmx$src$htmx$$get_indicator(_indicator_owner);
        if (_bind$3 === undefined) {
          return undefined;
        } else {
          const _Some$3 = _bind$3;
          const _selector = _Some$3;
          f4ah6o$htmx$src$htmx$$log_debug_attr(`resolve_inherit_from_parent: selector = '${_selector}'`);
          if (moonbitlang$core$string$$String$contains(_selector, { str: f4ah6o$htmx$src$htmx$$resolve_inherit_from_parent$46$42$bind$124$1109, start: 0, end: f4ah6o$htmx$src$htmx$$resolve_inherit_from_parent$46$42$bind$124$1109.length })) {
            const _bind$4 = f4ah6o$htmx$src$htmx$$resolve_inherit_from_parent(_indicator_owner);
            if (_bind$4 === undefined) {
              return f4ah6o$htmx$src$htmx$$extract_non_inherit(_selector);
            } else {
              const _Some$4 = _bind$4;
              const _inherited = _Some$4;
              return f4ah6o$htmx$src$htmx$$combine_selectors(_inherited, _selector);
            }
          } else {
            return _selector;
          }
        }
      } else {
        f4ah6o$htmx$src$htmx$$log_debug_attr("resolve_inherit_from_parent: closest not found, trying grandparent");
        _tmp = _parent;
        continue;
      }
    } else {
      f4ah6o$htmx$src$htmx$$log_debug_attr("resolve_inherit_from_parent: no parent found");
      return undefined;
    }
  }
}
function f4ah6o$htmx$src$htmx$$resolve_inherit(element, selector) {
  f4ah6o$htmx$src$htmx$$log_debug_attr(`resolve_inherit: selector = '${selector}'`);
  const parts = f4ah6o$htmx$src$htmx$$split_by_comma(selector);
  const results = [];
  const _len = parts.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const part = parts[_i];
      f4ah6o$htmx$src$htmx$$log_debug_attr(`resolve_inherit: part = '${part}', trim = '${f4ah6o$htmx$src$htmx$$trim_string(part)}'`);
      if (part === "inherit") {
        f4ah6o$htmx$src$htmx$$log_debug_attr("resolve_inherit: part is inherit, calling resolve_inherit_from_parent");
        const _bind = f4ah6o$htmx$src$htmx$$resolve_inherit_from_parent(element);
        if (_bind === undefined) {
          f4ah6o$htmx$src$htmx$$log_debug_attr("resolve_inherit: inherited is None");
        } else {
          const _Some = _bind;
          const _inherited = _Some;
          f4ah6o$htmx$src$htmx$$log_debug_attr(`resolve_inherit: inherited = '${_inherited}'`);
          const inherited_parts = f4ah6o$htmx$src$htmx$$split_by_comma(_inherited);
          const _len$2 = inherited_parts.length;
          let _tmp$2 = 0;
          while (true) {
            const _i$2 = _tmp$2;
            if (_i$2 < _len$2) {
              const p = inherited_parts[_i$2];
              const _p = "";
              if (!(p === _p)) {
                moonbitlang$core$array$$Array$push$7$(results, p);
              }
              _tmp$2 = _i$2 + 1 | 0;
              continue;
            } else {
              break;
            }
          }
        }
      } else {
        const _p = "";
        if (!(part === _p)) {
          moonbitlang$core$array$$Array$push$7$(results, part);
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const result = f4ah6o$htmx$src$htmx$$join_with_comma(results);
  f4ah6o$htmx$src$htmx$$log_debug_attr(`resolve_inherit: result = '${result}'`);
  return result;
}
function f4ah6o$htmx$src$htmx$$get_indicator_elements(element) {
  const _bind = f4ah6o$htmx$src$htmx$$find_indicator_owner(element);
  if (_bind === undefined) {
    f4ah6o$htmx$src$htmx$$log_debug_attr("get_indicator_elements: no indicator found, using element itself");
    return [element];
  } else {
    const _Some = _bind;
    const _x = _Some;
    const _owner = _x._0;
    const _selector = _x._1;
    f4ah6o$htmx$src$htmx$$log_debug_attr(`get_indicator_elements: found owner with selector '${_selector}'`);
    const resolved = f4ah6o$htmx$src$htmx$$resolve_inherit(_owner, _selector);
    f4ah6o$htmx$src$htmx$$log_debug_attr(`get_indicator_elements: resolved selector '${resolved}'`);
    const result = f4ah6o$htmx$src$htmx$$find_targets_by_selector(_owner, resolved);
    f4ah6o$htmx$src$htmx$$log_debug_attr(`get_indicator_elements: found ${moonbitlang$core$int$$Int$to_string$46$inner(result.length, 10)} targets`);
    return result.length === 0 ? [element] : result;
  }
}
function f4ah6o$htmx$src$htmx$$find_inherited_attribute(element, attr_name) {
  let _tmp = element;
  while (true) {
    const element$2 = _tmp;
    const _bind = f4ah6o$htmx$src$htmx$$get_parent_element(element$2);
    if (_bind.$tag === 1) {
      const _Some = _bind;
      const _parent = _Some._0;
      const _bind$2 = mizchi$js$browser$dom$$Element$getAttribute(_parent, attr_name);
      if (_bind$2 === undefined) {
        const data_attr = `data-${attr_name}`;
        const _bind$3 = mizchi$js$browser$dom$$Element$getAttribute(_parent, data_attr);
        if (_bind$3 === undefined) {
          _tmp = _parent;
          continue;
        } else {
          const _Some$2 = _bind$3;
          const _value = _Some$2;
          return _value;
        }
      } else {
        const _Some$2 = _bind$2;
        const _value = _Some$2;
        return _value;
      }
    } else {
      return undefined;
    }
  }
}
function f4ah6o$htmx$src$htmx$$get_hx_inherit(element) {
  const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, "hx-inherit");
  if (_bind === undefined) {
    return mizchi$js$browser$dom$$Element$getAttribute(element, "data-hx-inherit");
  } else {
    const _Some = _bind;
    const _value = _Some;
    return _value;
  }
}
function f4ah6o$htmx$src$htmx$$find_inherited_attribute_with_check(element, attr_name) {
  let _tmp = element;
  while (true) {
    const element$2 = _tmp;
    const _bind = f4ah6o$htmx$src$htmx$$get_parent_element(element$2);
    if (_bind.$tag === 1) {
      const _Some = _bind;
      const _parent = _Some._0;
      const _bind$2 = f4ah6o$htmx$src$htmx$$get_hx_inherit(_parent);
      if (_bind$2 === undefined) {
        _tmp = _parent;
        continue;
      } else {
        const _Some$2 = _bind$2;
        const _inherit_value = _Some$2;
        const inherit_array = f4ah6o$htmx$src$htmx$$parse_hx_inherit(_inherit_value);
        const inherits_all = f4ah6o$htmx$src$htmx$$check_inherits_all(inherit_array);
        const inherits_this = f4ah6o$htmx$src$htmx$$check_includes_attribute(inherit_array, attr_name);
        if (inherits_all || inherits_this) {
          const _bind$3 = mizchi$js$browser$dom$$Element$getAttribute(_parent, attr_name);
          if (_bind$3 === undefined) {
            const data_attr = `data-${attr_name}`;
            const _bind$4 = mizchi$js$browser$dom$$Element$getAttribute(_parent, data_attr);
            if (_bind$4 === undefined) {
              _tmp = _parent;
              continue;
            } else {
              const _Some$3 = _bind$4;
              const _value = _Some$3;
              return _value;
            }
          } else {
            const _Some$3 = _bind$3;
            const _value = _Some$3;
            return _value;
          }
        } else {
          _tmp = _parent;
          continue;
        }
      }
    } else {
      return undefined;
    }
  }
}
function f4ah6o$htmx$src$htmx$$should_inherit_attribute(element, attr_name) {
  const disabled = f4ah6o$htmx$src$htmx$$get_disable_inheritance();
  if (!disabled) {
    return f4ah6o$htmx$src$htmx$$find_inherited_attribute(element, attr_name);
  }
  return f4ah6o$htmx$src$htmx$$find_inherited_attribute_with_check(element, attr_name);
}
function f4ah6o$htmx$src$htmx$$get_swap_style_with_inherit(element) {
  const swap_attr = "hx-swap";
  const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, swap_attr);
  if (_bind === undefined) {
    const _bind$2 = mizchi$js$browser$dom$$Element$getAttribute(element, `data-${swap_attr}`);
    if (_bind$2 === undefined) {
      const _bind$3 = f4ah6o$htmx$src$htmx$$should_inherit_attribute(element, swap_attr);
      if (_bind$3 === undefined) {
        return 0;
      } else {
        const _Some = _bind$3;
        const _inherited_value = _Some;
        return f4ah6o$htmx$src$htmx$$SwapStyle$parse(_inherited_value);
      }
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      return f4ah6o$htmx$src$htmx$$SwapStyle$parse(_value);
    }
  } else {
    const _Some = _bind;
    const _value = _Some;
    return f4ah6o$htmx$src$htmx$$SwapStyle$parse(_value);
  }
}
function f4ah6o$htmx$src$htmx$$get_target_with_inherit(element) {
  const target_attr = "hx-target";
  const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, target_attr);
  let result;
  if (_bind === undefined) {
    result = mizchi$js$browser$dom$$Element$getAttribute(element, `data-${target_attr}`);
  } else {
    const _Some = _bind;
    const _selector = _Some;
    result = _selector;
  }
  if (result === undefined) {
    const _bind$2 = f4ah6o$htmx$src$htmx$$should_inherit_attribute(element, target_attr);
    if (_bind$2 === undefined) {
      return element;
    } else {
      const _Some = _bind$2;
      const _inherited_selector = _Some;
      const _bind$3 = f4ah6o$htmx$src$htmx$$parse_extended_target(element, _inherited_selector);
      if (_bind$3.$tag === 1) {
        const _Some$2 = _bind$3;
        return _Some$2._0;
      } else {
        return element;
      }
    }
  } else {
    const _Some = result;
    const _selector = _Some;
    const _bind$2 = f4ah6o$htmx$src$htmx$$parse_extended_target(element, _selector);
    if (_bind$2.$tag === 1) {
      const _Some$2 = _bind$2;
      return _Some$2._0;
    } else {
      return element;
    }
  }
}
function f4ah6o$htmx$src$htmx$$show_indicators(elements) {
  const _len = elements.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const el = elements[_i];
      f4ah6o$htmx$src$htmx$$inc_indicator_count(el);
      f4ah6o$htmx$src$htmx$$add_request_class(el);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function f4ah6o$htmx$src$htmx$$values_to_query_string(values) {
  if (values.length === 0) {
    return "";
  }
  const parts = [];
  const _len = values.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const pair = values[_i];
      const _name = pair._0;
      const _value = pair._1;
      const encoded_name = f4ah6o$htmx$src$htmx$$url_encode(_name);
      const encoded_value = f4ah6o$htmx$src$htmx$$url_encode(_value);
      moonbitlang$core$array$$Array$push$7$(parts, `${encoded_name}=${encoded_value}`);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return moonbitlang$core$array$$Array$join$7$(parts, { str: f4ah6o$htmx$src$htmx$$values_to_query_string$46$42$bind$124$1233, start: 0, end: f4ah6o$htmx$src$htmx$$values_to_query_string$46$42$bind$124$1233.length });
}
function f4ah6o$htmx$src$htmx$$process_element_with_trigger(element, trigger_el) {
  f4ah6o$htmx$src$htmx$$log_debug("process_element_with_trigger called");
  const method_url = f4ah6o$htmx$src$htmx$$find_method_url(element);
  if (method_url === undefined) {
    return;
  } else {
    const _Some = method_url;
    const _x = _Some;
    const _http_method = _x._0;
    const _url = _x._1;
    if (!f4ah6o$htmx$src$htmx$$validate_element_with_trigger(element, trigger_el)) {
      return undefined;
    }
    const target = f4ah6o$htmx$src$htmx$$get_target_with_inherit(element);
    const swap_style = f4ah6o$htmx$src$htmx$$get_swap_style_with_inherit(element);
    const swap_style_str = f4ah6o$htmx$src$htmx$$SwapStyle$to_htmx_string(swap_style);
    const _bind = f4ah6o$htmx$src$htmx$$get_disabled_elt(element);
    let disabled_elements;
    if (_bind === undefined) {
      f4ah6o$htmx$src$htmx$$log_debug("No disabled-elt attribute found");
      disabled_elements = [];
    } else {
      const _Some$2 = _bind;
      const _selector = _Some$2;
      f4ah6o$htmx$src$htmx$$log_debug(`Found disabled-elt selector: ${_selector}`);
      disabled_elements = f4ah6o$htmx$src$htmx$$find_targets_by_selector(element, _selector);
    }
    f4ah6o$htmx$src$htmx$$log_debug(`Disabled elements count: ${moonbitlang$core$int$$Int$to_string$46$inner(disabled_elements.length, 10)}`);
    const indicator_elements = f4ah6o$htmx$src$htmx$$get_indicator_elements(element);
    if (indicator_elements.length > 0) {
      f4ah6o$htmx$src$htmx$$log_debug(`Found ${moonbitlang$core$int$$Int$to_string$46$inner(indicator_elements.length, 10)} indicator element(s)`);
    } else {
      f4ah6o$htmx$src$htmx$$log_debug("No indicator attribute found, using element itself");
    }
    f4ah6o$htmx$src$htmx$$log_debug(`Indicator elements count: ${moonbitlang$core$int$$Int$to_string$46$inner(indicator_elements.length, 10)}`);
    if (indicator_elements.length > 0) {
      f4ah6o$htmx$src$htmx$$log_debug(`About to call show_indicators with count: ${moonbitlang$core$int$$Int$to_string$46$inner(indicator_elements.length, 10)}`);
      f4ah6o$htmx$src$htmx$$show_indicators(indicator_elements);
      f4ah6o$htmx$src$htmx$$log_debug("show_indicators returned");
    }
    if (disabled_elements.length > 0) {
      f4ah6o$htmx$src$htmx$$log_debug(`About to call disable_elements with count: ${moonbitlang$core$int$$Int$to_string$46$inner(disabled_elements.length, 10)}`);
      f4ah6o$htmx$src$htmx$$disable_elements(disabled_elements);
      f4ah6o$htmx$src$htmx$$log_debug("disable_elements returned");
    }
    const callback = f4ah6o$htmx$src$htmx$$create_response_callback(element, target, swap_style_str, _url, disabled_elements, indicator_elements);
    const expression_vars = f4ah6o$htmx$src$htmx$$get_expression_vars(new Option$Some$1$(element), Option$None$3$);
    if (f4ah6o$htmx$src$htmx$$HttpMethod$has_body(_http_method)) {
      const form_data = f4ah6o$htmx$src$htmx$$get_form_data(element);
      if (form_data.$tag === 1) {
        const _Some$2 = form_data;
        const _fd = _Some$2._0;
        f4ah6o$htmx$src$htmx$$append_vars_to_form_data(_fd, f4ah6o$htmx$src$htmx$$map_to_any(expression_vars));
        f4ah6o$htmx$src$htmx$$request_with_form_async(_url, _http_method, new Option$Some$2$(_fd), new Option$Some$1$(element), callback);
        return;
      } else {
        const vars_any = f4ah6o$htmx$src$htmx$$map_to_any(expression_vars);
        const form_data_with_inputs = f4ah6o$htmx$src$htmx$$create_form_data_from_inputs_and_vars(element, vars_any);
        f4ah6o$htmx$src$htmx$$request_with_form_async(_url, _http_method, new Option$Some$2$(form_data_with_inputs), new Option$Some$1$(element), callback);
        return;
      }
    } else {
      const _bind$2 = f4ah6o$htmx$src$htmx$$get_form_data(element);
      let actual_url;
      if (_bind$2.$tag === 1) {
        const values = f4ah6o$htmx$src$htmx$$collect_input_values(element);
        const query = f4ah6o$htmx$src$htmx$$values_to_query_string(values);
        const base_url = f4ah6o$htmx$src$htmx$$append_query_string(_url, query);
        actual_url = f4ah6o$htmx$src$htmx$$append_vars_to_url(base_url, f4ah6o$htmx$src$htmx$$map_to_any(expression_vars));
      } else {
        actual_url = f4ah6o$htmx$src$htmx$$append_vars_to_url(_url, f4ah6o$htmx$src$htmx$$map_to_any(expression_vars));
      }
      f4ah6o$htmx$src$htmx$$request_async(actual_url, _http_method, new Option$Some$1$(element), callback);
      return;
    }
  }
}
function f4ah6o$htmx$src$htmx$$process_element(element) {
  f4ah6o$htmx$src$htmx$$process_element_with_trigger(element, Option$None$1$);
}
function f4ah6o$htmx$src$htmx$$find_htmx_element(element) {
  const methods = ["hx-get", "hx-post", "hx-put", "hx-delete", "hx-patch"];
  const _len = methods.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const method_attr = methods[_i];
      if (mizchi$js$browser$dom$$Element$hasAttribute(element, method_attr)) {
        return new Option$Some$1$(element);
      }
      const data_attr = `data-${method_attr}`;
      if (mizchi$js$browser$dom$$Element$hasAttribute(element, data_attr)) {
        return new Option$Some$1$(element);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return mizchi$js$browser$dom$$Element$closest(element, "[hx-get], [hx-post], [hx-put], [hx-delete], [hx-patch], [data-hx-get], [data-hx-post], [data-hx-put], [data-hx-delete], [data-hx-patch]");
}
function f4ah6o$htmx$src$htmx$$get_default_trigger(element) {
  const tag = moonbitlang$core$string$$String$to_lower(mizchi$js$browser$dom$$Element$tagName(element));
  switch (tag) {
    case "input": {
      return "change";
    }
    case "textarea": {
      return "change";
    }
    case "select": {
      return "change";
    }
    case "form": {
      return "submit";
    }
    default: {
      return "click";
    }
  }
}
function f4ah6o$htmx$src$htmx$$get_trigger_event(element) {
  const trigger_attr = "hx-trigger";
  const _bind = mizchi$js$browser$dom$$Element$getAttribute(element, trigger_attr);
  let result;
  if (_bind === undefined) {
    result = mizchi$js$browser$dom$$Element$getAttribute(element, `data-${trigger_attr}`);
  } else {
    const _Some = _bind;
    const _value = _Some;
    result = _value;
  }
  if (result === undefined) {
    return f4ah6o$htmx$src$htmx$$get_default_trigger(element);
  } else {
    const _Some = result;
    const _trigger = _Some;
    if (moonbitlang$core$string$$String$contains(_trigger, { str: f4ah6o$htmx$src$htmx$$get_trigger_event$46$42$bind$124$1259, start: 0, end: f4ah6o$htmx$src$htmx$$get_trigger_event$46$42$bind$124$1259.length })) {
      const chars = moonbitlang$core$string$$String$to_array(_trigger);
      let end_idx = chars.length;
      const _len = chars.length;
      let _tmp = 0;
      while (true) {
        const _i = _tmp;
        if (_i < _len) {
          const c = chars[_i];
          if (c === 32) {
            end_idx = _i;
            break;
          }
          _tmp = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return moonbitlang$core$string$$String$from_array(moonbitlang$core$array$$Array$sub$46$inner$11$(chars, 0, end_idx));
    } else {
      return _trigger;
    }
  }
}
function f4ah6o$htmx$src$htmx$$handle_click(evt) {
  const event = evt;
  const target_el = f4ah6o$htmx$src$htmx$$get_event_target(evt);
  if (f4ah6o$htmx$src$htmx$$is_submit_button(target_el)) {
    if (f4ah6o$htmx$src$htmx$$has_containing_form(target_el)) {
      const form = f4ah6o$htmx$src$htmx$$find_closest_form(target_el);
      const _bind = f4ah6o$htmx$src$htmx$$find_method_url(form);
      if (_bind === undefined) {
      } else {
        mizchi$js$web$event$$Event$preventDefault(event);
        f4ah6o$htmx$src$htmx$$process_element_with_trigger(form, new Option$Some$1$(target_el));
        return undefined;
      }
    }
  }
  const _bind = f4ah6o$htmx$src$htmx$$find_htmx_element(target_el);
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _htmx_el = _Some._0;
    const trigger = f4ah6o$htmx$src$htmx$$get_trigger_event(_htmx_el);
    if (trigger === "click" || trigger === "load") {
      mizchi$js$web$event$$Event$preventDefault(event);
      f4ah6o$htmx$src$htmx$$process_element_with_trigger(_htmx_el, new Option$Some$1$(target_el));
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function f4ah6o$htmx$src$htmx$$handle_change(evt) {
  const event = evt;
  const target_el = f4ah6o$htmx$src$htmx$$get_event_target(evt);
  const _bind = f4ah6o$htmx$src$htmx$$find_htmx_element(target_el);
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _htmx_el = _Some._0;
    const trigger = f4ah6o$htmx$src$htmx$$get_trigger_event(_htmx_el);
    if (trigger === "change") {
      mizchi$js$web$event$$Event$preventDefault(event);
      f4ah6o$htmx$src$htmx$$process_element(_htmx_el);
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function f4ah6o$htmx$src$htmx$$handle_submit(evt) {
  const event = evt;
  const target_el = f4ah6o$htmx$src$htmx$$get_event_target(evt);
  const submitter = f4ah6o$htmx$src$htmx$$get_event_submitter(evt);
  const _bind = f4ah6o$htmx$src$htmx$$find_htmx_element(target_el);
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _htmx_el = _Some._0;
    const trigger = f4ah6o$htmx$src$htmx$$get_trigger_event(_htmx_el);
    if (trigger === "submit") {
      mizchi$js$web$event$$Event$preventDefault(event);
      f4ah6o$htmx$src$htmx$$process_element_with_trigger(_htmx_el, submitter);
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function f4ah6o$htmx$src$htmx$$htmx_init() {
  const doc = mizchi$js$browser$dom$$document();
  const doc_target = doc;
  mizchi$js$web$event$$EventTarget$addEventListener$46$inner(doc_target, "click", f4ah6o$htmx$src$htmx$$handle_click, false, false, false, Option$None$4$);
  mizchi$js$web$event$$EventTarget$addEventListener$46$inner(doc_target, "change", f4ah6o$htmx$src$htmx$$handle_change, false, false, false, Option$None$4$);
  mizchi$js$web$event$$EventTarget$addEventListener$46$inner(doc_target, "submit", f4ah6o$htmx$src$htmx$$handle_submit, false, false, false, Option$None$4$);
  const doc_target_any = doc_target;
  f4ah6o$htmx$src$htmx$$init_hx_on_delegation(doc_target_any);
  f4ah6o$htmx$src$htmx$$process_load_triggers();
}
(() => {
  f4ah6o$htmx$src$htmx$$htmx_init();
})();
