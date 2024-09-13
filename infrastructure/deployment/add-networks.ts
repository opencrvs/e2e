import * as fs from 'fs'
import * as yaml from 'yaml'

interface DockerCompose {
  version: string
  services: Record<string, Service>
  networks: Record<string, Network>
}

interface Service {
  image?: string
  environment?: { [key: string]: string }
  volumes?: string[]
  ports?: string[]
  networks: string[]
}

interface Network {
  driver?: string
  external?: boolean
}

// Function to add networks to services and networks section
function addNetworksToCompose(composeFile: string, networksList: string) {
  // Read and parse the existing docker-compose YAML file
  const fileContent = fs.readFileSync(composeFile, 'utf8')
  const composeObject = yaml.parse(fileContent) as DockerCompose

  // Convert the comma-separated networks list into an array
  const networksArray = networksList
    .split(',')
    .map((network) => network.trim())
    .filter((network) => network.length > 0)
    .map((stack) => `${stack}_dependencies_net`)
    .concat('traefik_net')

  // Add networks to each service
  for (const serviceName in composeObject.services) {
    if (serviceName in composeObject.services) {
      const service = composeObject.services[serviceName]
      if (!service.networks) {
        service.networks = []
      }
      networksArray.forEach((network) => {
        if (!service.networks.includes(network)) {
          service.networks.push(network)
        }
      })
    }
  }

  // Add networks to the global networks section
  if (!composeObject.networks) {
    composeObject.networks = {}
  }

  networksArray.forEach((network) => {
    if (!composeObject.networks[network]) {
      composeObject.networks[network] = { driver: 'overlay' }
    }
  })

  // Convert the updated object back to YAML and output it
  const updatedComposeYaml = yaml.stringify(composeObject)
  console.log(updatedComposeYaml)
}

// Parse arguments from the command line
const [composeFile, networksList] = process.argv.slice(2)

if (!composeFile || !networksList) {
  console.error(
    'Usage: ts-node script.ts <docker-compose-file> <networks-list>'
  )
  process.exit(1)
}

// Call the function to update the compose file
addNetworksToCompose(composeFile, networksList)
