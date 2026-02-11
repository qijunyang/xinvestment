const fs = require('fs');
const path = require('path');

// AWS Parameter Store integration - Currently disabled, will be added in future update
// To enable AWS support:
// 1. npm install aws-sdk
// 2. Initialize SSM client: const ssm = new AWS.SSM({ region: process.env.AWS_REGION || 'us-east-1' });
// 3. Uncomment getParameter and replaceTokens implementation below
// const AWS = require('aws-sdk');
// const ssm = new AWS.SSM({ region: process.env.AWS_REGION || 'us-east-1' });

/**
 * Deep merge two objects, with source values overriding target values
 * @param {object} target - The base object
 * @param {object} source - The object to merge in (overrides target)
 * @returns {object} - The merged object
 */
function deepMerge(target, source) {
  const result = { ...target };
  
  for (const key in source) {
    if (source.hasOwnProperty(key)) {
      if (typeof source[key] === 'object' && source[key] !== null && !Array.isArray(source[key])) {
        result[key] = deepMerge(result[key] || {}, source[key]);
      } else {
        result[key] = source[key];
      }
    }
  }
  
  return result;
}

/**
 * Fetch a secret from AWS Parameter Store
 * Currently disabled - will be implemented in future update
 * @param {string} parameterName - The parameter name path
 * @returns {Promise<string>} - The parameter value
 */
// async function getParameter(parameterName) {
//   try {
//     const params = {
//       Name: parameterName,
//       WithDecryption: true
//     };
//     const response = await ssm.getParameter(params).promise();
//     return response.Parameter.Value;
//   } catch (error) {
//     console.error(`Failed to retrieve parameter ${parameterName}:`, error);
//     throw new Error(`Failed to fetch secret from AWS Parameter Store: ${parameterName}`);
//   }
// }

/**
 * Replace all tokens in config file with values from AWS Parameter Store
 * Currently disabled - will be implemented in future update
 * Framework preserved for easy re-enablement
 * @param {object} config - The configuration object
 * @param {string} env - The environment name
 * @returns {Promise<object>} - The updated configuration object
 */
async function replaceTokens(config, env) {
  // Token replacement from AWS Parameter Store currently disabled
  // To re-enable:
  // 1. Uncomment the original implementation above
  // 2. Uncomment getParameter function
  // 3. npm install aws-sdk
  // 4. Ensure valid AWS credentials are configured
  
  const tokenPattern = /@(\w+)@/g;
  const configStr = JSON.stringify(config);
  const hasTokens = tokenPattern.test(configStr);
  
  if (hasTokens) {
    console.log('⚠ Tokens found in config, but AWS Parameter Store is currently disabled');
    console.log('To enable AWS support, uncomment code in configLoader.js and install aws-sdk');
  }
  
  return config;
}
// Original implementation (commented out for future use):
// async function replaceTokens(config, env) {
//   const tokenPattern = /@(\w+)@/g;
//   
//   /**
//    * Recursively replace tokens in an object
//    */
//   async function replaceInObject(obj) {
//     for (const key in obj) {
//       if (typeof obj[key] === 'string') {
//         const matches = obj[key].match(tokenPattern);
//         if (matches) {
//           for (const match of matches) {
//             const tokenName = match.slice(1, -1).toLowerCase(); // Remove @ symbols
//             const parameterPath = `/mytodo/${env}/${key}/${tokenName}`;
//             try {
//               const value = await getParameter(parameterPath);
//               obj[key] = obj[key].replace(match, value);
//               console.log(`✓ Replaced token ${match} from ${parameterPath}`);
//             } catch (error) {
//               console.warn(`⚠ AWS Parameter Store unavailable: Could not replace token ${match}. Keeping original value. ${error.message}`);
//             }
//           }
//         }
//       } else if (typeof obj[key] === 'object' && obj[key] !== null) {
//         await replaceInObject(obj[key]);
//       }
//     }
//   }
//   
//   await replaceInObject(config);
//   return config;
// }

/**
 * Load and initialize configuration with secrets from AWS
 * Process: Load defaults -> Load env-specific -> Merge -> Replace tokens from AWS -> Return
 * @param {string} env - The environment name (dev, qa, stg, uat, prd, dr)
 * @returns {Promise<object>} - The fully initialized configuration object
 */
async function loadConfig(env) {
  try {
    console.log(`Loading configuration for environment: ${env}`);
    
    // Step 1: Load default config
    const defaultConfigPath = path.join(__dirname, 'config-default.js');
    delete require.cache[require.resolve(defaultConfigPath)];
    const defaultConfig = require(defaultConfigPath);
    console.log('✓ Default config loaded');
    
    // Step 2: Load environment-specific config
    const envConfigPath = path.join(__dirname, `config-${env}.js`);
    delete require.cache[require.resolve(envConfigPath)];
    const envConfig = require(envConfigPath);
    console.log(`✓ Environment config (${env}) loaded`);
    
    // Step 3: Merge configs (env-specific overrides defaults)
    const config = deepMerge(defaultConfig, envConfig);
    console.log('✓ Configs merged (environment-specific overrides defaults)');
    
    // Step 4: Token replacement from AWS Parameter Store is currently disabled
    // AWS support can be re-enabled by uncommenting code in this file and installing aws-sdk
    // When enabled, this will replace @token@ placeholders with values from AWS Parameter Store
    
    return config;
  } catch (error) {
    console.error('✗ Failed to load configuration:', error.message);
    throw error;
  }
}

module.exports = {
  loadConfig,
  // getParameter is commented out - AWS support currently disabled
  // getParameter,
  replaceTokens
  // To enable AWS support, uncomment getParameter and the original replaceTokens implementation
};
