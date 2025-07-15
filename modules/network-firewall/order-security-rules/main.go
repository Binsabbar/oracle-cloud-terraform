package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"

	"github.com/oracle/oci-go-sdk/v65/common"
	"github.com/oracle/oci-go-sdk/v65/networkfirewall"
	"github.com/spf13/pflag"
)

type FirewallRule struct {
	Name     string `json:"name"`
	Position int    `json:"position"`
}

type RulesData struct {
	Rules []FirewallRule `json:"rules"`
}

var inputFile = pflag.StringP("input", "i", "", "Path to input JSON file containing firewall rules")
var policyId = pflag.StringP("policyId", "p", "", "OCI Network Firewall Policy ID to update")
var ociConfigFile = pflag.StringP("oci-config-path", "o", "", "OCI config file path")

func main() {
	pflag.Parse()
	checkFlags()

	rulesData := parseSecurityRulesFromJSONFile(inputFile)
	configProvider := loadConfigProvider()
	nwClient, err := networkfirewall.NewNetworkFirewallClientWithConfigurationProvider(configProvider)
	if err != nil {
		log.Fatalf("Error creating network firewall policy client: %v", err)
	}

	checkPolicyIdExist(nwClient, *policyId)
	orderSecurityRules(nwClient, *policyId, rulesData)
}

func orderSecurityRules(client networkfirewall.NetworkFirewallClient, policyId string, rulesData RulesData) {
	for index, rule := range rulesData.Rules {
		existingRule := getSecurityRule(client, policyId, rule.Name)
		position := getPosition(index, rulesData)
		existingRule.Position = position
		updateSecurityRule(client, policyId, existingRule)
	}
}

func getPosition(index int, rulesData RulesData) *networkfirewall.RulePosition {
	if index > 0 {
		return  &networkfirewall.RulePosition{AfterRule: common.String(rulesData.Rules[index-1].Name)}
	} else {
		return &networkfirewall.RulePosition{BeforeRule: common.String(rulesData.Rules[index+1].Name)}
	}
}

func getSecurityRule(client networkfirewall.NetworkFirewallClient, policyId string, ruleName string) networkfirewall.SecurityRule {
	request := networkfirewall.GetSecurityRuleRequest{
		NetworkFirewallPolicyId: common.String(policyId),
		SecurityRuleName:        common.String(ruleName),
	}
	ctx := context.Background()
	response, err := client.GetSecurityRule(ctx, request)
	if err != nil {
		log.Fatalf("Error finding security rule %s: %v",ruleName, err)
	}

	log.Printf("Fetched Security Rule: %s\n", *response.SecurityRule.Name)
	return response.SecurityRule
}

func updateSecurityRule(client networkfirewall.NetworkFirewallClient, policyId string, rule networkfirewall.SecurityRule) {
	updateRequest := networkfirewall.UpdateSecurityRuleRequest{
		NetworkFirewallPolicyId: common.String(policyId),
		SecurityRuleName:        rule.Name,
		UpdateSecurityRuleDetails: networkfirewall.UpdateSecurityRuleDetails{
			Action:     rule.Action,
			Condition:  rule.Condition,
			Inspection: rule.Inspection,
			Position:   rule.Position,
		},
	}

	ctx := context.Background()
	_, err := client.UpdateSecurityRule(ctx, updateRequest)
	if err != nil {
		log.Fatalf("Error updating network firewall security rule %s: %v\n",*rule.Name, err)
	}

	fmt.Printf("Network Firewall Security Rule '%s' updated successfully\n", *rule.Name)
}

func checkPolicyIdExist(client networkfirewall.NetworkFirewallClient, policyId string) {
	request := networkfirewall.GetNetworkFirewallPolicyRequest{
		NetworkFirewallPolicyId: common.String(policyId),
	}

	ctx := context.Background()
	_, err := client.GetNetworkFirewallPolicy(ctx, request)
	if err != nil {
		log.Fatalf("Error getting network firewall policy: %v", err)
	}
	log.Printf("Policy is valid: %s", policyId)
}

func parseSecurityRulesFromJSONFile(inputFile *string) RulesData {
	fileContent, err := os.ReadFile(*inputFile)
	if err != nil {
		log.Fatalf("Error reading input file: %v", err)
	}

	var rulesData RulesData
	if err := json.Unmarshal(fileContent, &rulesData); err != nil {
		log.Fatalf("Error unmarshalling JSON: %v", err)
	}

	sort.SliceStable(rulesData.Rules, func(i, j int) bool {
		return rulesData.Rules[i].Position < rulesData.Rules[j].Position
	})

	return rulesData
}

func checkFlags() {
	if *inputFile == "" {
		log.Fatal("Input file path is required. Use the -input flag to specify the JSON file.")
	}

	if *policyId == "" {
		log.Fatal("OCI Network Firewall Policy ID is required. Use the -policyId flag to specify the policy ID.")
	}
}

func loadConfigProvider() common.ConfigurationProvider {
	var configProvider common.ConfigurationProvider
	var configErr error
	if *ociConfigFile != "" {
		configProvider, configErr = common.ConfigurationProviderFromFile(*ociConfigFile, "")
		if configErr != nil {
			log.Fatalf("Error reading config file: %v", configErr)
		}
		log.Printf("Using Config File at %s\n", *ociConfigFile)
	} else {
		configProvider = common.DefaultConfigProvider()
	}
	return configProvider
}
